package admin

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"animeat/backend/internal/cache"
	"animeat/backend/internal/database"
	"animeat/backend/internal/platform"
	"github.com/jackc/pgx/v5"
)

type Service struct {
	db    *database.Postgres
	cache *cache.RedisClient
}

func NewService(db *database.Postgres, cache *cache.RedisClient) *Service {
	return &Service{db: db, cache: cache}
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

// GetDashboardStats computes platform-wide operational metrics.
func (s *Service) GetDashboardStats(ctx context.Context) (*DashboardStats, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	startOfDay := time.Now().UTC().Truncate(24 * time.Hour)

	stats := &DashboardStats{StatusBreakdown: map[string]int{}}

	err := s.db.Pool.QueryRow(ctx, `
		SELECT
			COUNT(*) FILTER (WHERE order_time >= $1),
			COALESCE(SUM(total_amount_paise) FILTER (WHERE order_time >= $1 AND status IN ('delivered', 'completed')), 0),
			COUNT(*),
			(SELECT COUNT(*) FROM riders WHERE is_online AND is_approved),
			(SELECT COUNT(*) FROM riders WHERE approval_status = 'pending'),
			(SELECT COUNT(*) FROM vendors),
			(SELECT COUNT(*) FROM items WHERE is_active),
			(SELECT COUNT(*) FROM users)
		FROM orders
	`, startOfDay).Scan(
		&stats.OrdersToday, &stats.RevenueToday, &stats.TotalOrders,
		&stats.ActiveRiders, &stats.PendingApprovals,
		&stats.VendorCount, &stats.ItemCount, &stats.UserCount,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to compute dashboard stats: %w", err)
	}

	rows, err := s.db.Pool.Query(ctx, `SELECT status, COUNT(*) FROM orders GROUP BY status`)
	if err != nil {
		return nil, fmt.Errorf("failed to compute status breakdown: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var status string
		var count int
		if err := rows.Scan(&status, &count); err != nil {
			return nil, fmt.Errorf("failed to scan status row: %w", err)
		}
		stats.StatusBreakdown[status] = count
	}

	return stats, rows.Err()
}

// ---------------------------------------------------------------------------
// Orders (admin console)
// ---------------------------------------------------------------------------

// ListOrders returns every order with the customer's name and address.
func (s *Service) ListOrders(ctx context.Context, status string) ([]AdminOrder, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	query := `
		SELECT o.id, o.user_id, o.vendor_id, o.status, o.items,
		       o.subtotal_paise, o.delivery_fee_paise, o.discount_paise, o.total_amount_paise,
		       o.payment_method, o.payment_status, o.special_notes, o.rider_id, o.order_time,
		       COALESCE(u.name, ''),
		       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip))
		FROM orders o
		LEFT JOIN users u ON u.id = o.user_id`
	var args []interface{}
	if status != "" {
		query += " WHERE o.status = $1"
		args = append(args, status)
	}
	query += " ORDER BY o.order_time DESC"

	rows, err := s.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list admin orders: %w", err)
	}
	defer rows.Close()

	var orders []AdminOrder
	for rows.Next() {
		var o AdminOrder
		var itemsJSON []byte
		if err := rows.Scan(
			&o.ID, &o.UserID, &o.VendorID, &o.Status, &itemsJSON,
			&o.Subtotal, &o.DeliveryFee, &o.Discount, &o.TotalAmount,
			&o.PaymentMethod, &o.PaymentStatus, &o.SpecialNotes,
			&o.RiderID, &o.OrderTime, &o.CustomerName, &o.Address,
		); err != nil {
			return nil, fmt.Errorf("failed to scan admin order: %w", err)
		}
		if len(itemsJSON) > 0 {
			_ = json.Unmarshal(itemsJSON, &o.Items)
		}
		orders = append(orders, o)
	}

	return orders, rows.Err()
}

// ListUsers returns the customer records used by the order console.
func (s *Service) ListUsers(ctx context.Context) ([]AdminUser, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Pool.Query(ctx, `
		SELECT id, COALESCE(name, ''), COALESCE(email, '') FROM users ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to list users: %w", err)
	}
	defer rows.Close()

	var users []AdminUser
	for rows.Next() {
		var u AdminUser
		if err := rows.Scan(&u.ID, &u.Name, &u.Email); err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, u)
	}

	return users, rows.Err()
}

// ---------------------------------------------------------------------------
// Rider management
// ---------------------------------------------------------------------------

// ListRiders returns all rider records, optionally filtered by approval status.
func (s *Service) ListRiders(ctx context.Context, status string) ([]AdminRider, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	query := `
		SELECT id, name, phone, email, is_online, is_approved, approval_status,
		       rejection_reason, created_at, updated_at
		FROM riders`
	var args []interface{}
	if status != "" {
		query += " WHERE approval_status = $1"
		args = append(args, status)
	}
	query += " ORDER BY created_at DESC"

	rows, err := s.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to list riders: %w", err)
	}
	defer rows.Close()

	var riders []AdminRider
	for rows.Next() {
		var r AdminRider
		if err := rows.Scan(
			&r.ID, &r.Name, &r.Phone, &r.Email, &r.IsOnline,
			&r.IsApproved, &r.ApprovalStatus, &r.RejectionReason,
			&r.CreatedAt, &r.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan rider: %w", err)
		}
		riders = append(riders, r)
	}

	return riders, rows.Err()
}

// SetRiderApproval approves or rejects a rider application.
func (s *Service) SetRiderApproval(ctx context.Context, riderID string, req *RiderApprovalRequest) (*AdminRider, error) {
	if req.ApprovalStatus != "approved" && req.ApprovalStatus != "rejected" {
		return nil, fmt.Errorf("%w: approval_status must be 'approved' or 'rejected'", platform.ErrInvalidInput)
	}

	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	approved := req.ApprovalStatus == "approved"

	var updated bool
	err := s.db.Pool.QueryRow(ctx, `
		UPDATE riders
		SET approval_status = $2, is_approved = $3,
		    rejection_reason = CASE WHEN $4 THEN $5 ELSE NULL END,
		    is_online = CASE WHEN $3 THEN is_online ELSE FALSE END,
		    updated_at = NOW()
		WHERE id = $1
		RETURNING TRUE
	`, riderID, req.ApprovalStatus, approved, req.ApprovalStatus == "rejected", req.RejectionReason).Scan(&updated)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to update rider approval: %w", err)
	}

	return s.GetRider(ctx, riderID)
}

// GetRider returns a single rider record.
func (s *Service) GetRider(ctx context.Context, riderID string) (*AdminRider, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var r AdminRider
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id, name, phone, email, is_online, is_approved, approval_status,
		       rejection_reason, created_at, updated_at
		FROM riders WHERE id = $1
	`, riderID).Scan(
		&r.ID, &r.Name, &r.Phone, &r.Email, &r.IsOnline,
		&r.IsApproved, &r.ApprovalStatus, &r.RejectionReason,
		&r.CreatedAt, &r.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch rider: %w", err)
	}

	return &r, nil
}

// ---------------------------------------------------------------------------
// App settings
// ---------------------------------------------------------------------------

// GetSettings returns the branding singleton (id = 1).
func (s *Service) GetSettings(ctx context.Context) (*AppSettings, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var a AppSettings
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id, home_video_url, show_hero_banner, hero_badge_text, hero_title,
		       hero_subtitle, hero_button_text, footer_subtitle, footer_support_links,
		       footer_legal_links, footer_copyright, updated_at
		FROM app_settings WHERE id = 1
	`).Scan(
		&a.ID, &a.HomeVideoURL, &a.ShowHeroBanner, &a.HeroBadgeText, &a.HeroTitle,
		&a.HeroSubtitle, &a.HeroButtonText, &a.FooterSubtitle, &a.FooterSupportLinks,
		&a.FooterLegalLinks, &a.FooterCopyright, &a.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch app settings: %w", err)
	}

	return &a, nil
}

// UpdateSettings updates the branding singleton.
func (s *Service) UpdateSettings(ctx context.Context, a *AppSettings) (*AppSettings, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	_, err := s.db.Pool.Exec(ctx, `
		UPDATE app_settings SET
			home_video_url      = COALESCE($1, home_video_url),
			show_hero_banner    = COALESCE($2, show_hero_banner),
			hero_badge_text     = COALESCE(NULLIF($3, ''), hero_badge_text),
			hero_title          = COALESCE(NULLIF($4, ''), hero_title),
			hero_subtitle       = COALESCE(NULLIF($5, ''), hero_subtitle),
			hero_button_text    = COALESCE(NULLIF($6, ''), hero_button_text),
			footer_subtitle     = COALESCE(NULLIF($7, ''), footer_subtitle),
			footer_support_links = COALESCE(NULLIF($8, ''), footer_support_links),
			footer_legal_links  = COALESCE(NULLIF($9, ''), footer_legal_links),
			footer_copyright    = COALESCE(NULLIF($10, ''), footer_copyright),
			updated_at          = NOW()
		WHERE id = 1
	`, a.HomeVideoURL, a.ShowHeroBanner, a.HeroBadgeText, a.HeroTitle,
		a.HeroSubtitle, a.HeroButtonText, a.FooterSubtitle, a.FooterSupportLinks,
		a.FooterLegalLinks, a.FooterCopyright)
	if err != nil {
		return nil, fmt.Errorf("failed to update app settings: %w", err)
	}

	return s.GetSettings(ctx)
}

// ---------------------------------------------------------------------------
// Catalog management (items / menus / deals)
// ---------------------------------------------------------------------------

// CreateItem inserts a new catalog item via canonical columns.
func (s *Service) CreateItem(ctx context.Context, req *AdminItemRequest) (*AdminItem, error) {
	if req.ItemTitle == "" || req.Price <= 0 {
		return nil, fmt.Errorf("%w: item_title and price are required", platform.ErrInvalidInput)
	}

	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	originalPrice := req.Price
	if req.OriginalPrice != nil && *req.OriginalPrice > 0 {
		originalPrice = *req.OriginalPrice
	}

	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}
	prepMin := 20
	if req.PreparationMin != nil && *req.PreparationMin > 0 {
		prepMin = *req.PreparationMin
	}

	var id string
	err := s.db.Pool.QueryRow(ctx, `
		INSERT INTO items (
			item_title, item_price, discount_price, description, thumbnail_url,
			category_id, vendor_id, is_active, name, price, original_price,
			category, image_url, is_available, preparation_min, rating, reviews_count,
			created_at, updated_at
		) VALUES (
			$1, $2 / 100.0, $3 / 100.0, $4, $5,
			$6, $7, $8, $1, $2, $3,
			COALESCE((SELECT menu_title FROM menus WHERE id = $6), 'General'), $5, $8, $9, 4.5, 0,
			NOW(), NOW()
		)
		RETURNING id
	`, req.ItemTitle, req.Price, originalPrice, req.Description, req.ThumbnailURL,
		req.CategoryID, req.VendorID, isActive, prepMin).Scan(&id)
	if err != nil {
		return nil, fmt.Errorf("failed to create item: %w", err)
	}

	s.invalidateCatalog(ctx)

	return s.GetItem(ctx, id)
}

// UpdateItem updates an existing catalog item.
func (s *Service) UpdateItem(ctx context.Context, itemID string, req *AdminItemRequest) (*AdminItem, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	originalPrice := req.Price
	if req.OriginalPrice != nil && *req.OriginalPrice > 0 {
		originalPrice = *req.OriginalPrice
	}
	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	tag, err := s.db.Pool.Exec(ctx, `
		UPDATE items SET
			item_title     = COALESCE(NULLIF($2, ''), item_title),
			name           = COALESCE(NULLIF($2, ''), name),
			item_price     = CASE WHEN $3 > 0 THEN $3 / 100.0 ELSE item_price END,
			discount_price = CASE WHEN $3 > 0 THEN $4 / 100.0 ELSE discount_price END,
			price          = CASE WHEN $3 > 0 THEN $3 ELSE price END,
			original_price = CASE WHEN $3 > 0 THEN $4 ELSE original_price END,
			description    = COALESCE(NULLIF($5, ''), description),
			thumbnail_url  = COALESCE(NULLIF($6, ''), thumbnail_url),
			image_url      = COALESCE(NULLIF($6, ''), image_url),
			category_id    = COALESCE($7, category_id),
			vendor_id      = COALESCE($8, vendor_id),
			is_active      = $9,
			is_available   = $9,
			updated_at     = NOW()
		WHERE id = $1
	`, itemID, req.ItemTitle, req.Price, originalPrice, req.Description,
		req.ThumbnailURL, req.CategoryID, req.VendorID, isActive)
	if err != nil {
		return nil, fmt.Errorf("failed to update item: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, platform.ErrNotFound
	}

	s.invalidateCatalog(ctx)

	return s.GetItem(ctx, itemID)
}

// DeleteItem soft-deletes (deactivates) a catalog item.
func (s *Service) DeleteItem(ctx context.Context, itemID string) error {
	if s.db == nil || s.db.Pool == nil {
		return platform.ErrInternal
	}

	tag, err := s.db.Pool.Exec(ctx, `
		UPDATE items SET is_active = FALSE, is_available = FALSE, updated_at = NOW()
		WHERE id = $1
	`, itemID)
	if err != nil {
		return fmt.Errorf("failed to deactivate item: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return platform.ErrNotFound
	}

	s.invalidateCatalog(ctx)
	return nil
}

// GetItem returns a single catalog item.
func (s *Service) GetItem(ctx context.Context, itemID string) (*AdminItem, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var i AdminItem
	var rawPrice, rawOrigPrice *int64
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id, item_title, price, original_price, description, thumbnail_url,
		       category_id, vendor_id, is_active, preparation_min, rating, reviews_count,
		       created_at, updated_at
		FROM items WHERE id = $1
	`, itemID).Scan(
		&i.ID, &i.ItemTitle, &rawPrice, &rawOrigPrice, &i.Description,
		&i.ThumbnailURL, &i.CategoryID, &i.VendorID, &i.IsActive,
		&i.PreparationMin, &i.Rating, &i.ReviewsCount,
		&i.CreatedAt, &i.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch item: %w", err)
	}

	if rawPrice != nil {
		i.Price = platform.FromPaise(*rawPrice)
	}
	if rawOrigPrice != nil {
		i.OriginalPrice = platform.FromPaise(*rawOrigPrice)
	}

	return &i, nil
}

// ListItems returns all catalog items (including inactive).
func (s *Service) ListItems(ctx context.Context) ([]AdminItem, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Pool.Query(ctx, `
		SELECT id, item_title, price, original_price, description, thumbnail_url,
		       category_id, vendor_id, is_active, preparation_min, rating, reviews_count,
		       created_at, updated_at
		FROM items ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to list items: %w", err)
	}
	defer rows.Close()

	var items []AdminItem
	for rows.Next() {
		var i AdminItem
		var rawPrice, rawOrigPrice *int64
		if err := rows.Scan(
			&i.ID, &i.ItemTitle, &rawPrice, &rawOrigPrice, &i.Description,
			&i.ThumbnailURL, &i.CategoryID, &i.VendorID, &i.IsActive,
			&i.PreparationMin, &i.Rating, &i.ReviewsCount,
			&i.CreatedAt, &i.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan item: %w", err)
		}
		if rawPrice != nil {
			i.Price = platform.FromPaise(*rawPrice)
		}
		if rawOrigPrice != nil {
			i.OriginalPrice = platform.FromPaise(*rawOrigPrice)
		}
		items = append(items, i)
	}

	return items, rows.Err()
}

// ListMenus returns all menus / categories.
func (s *Service) ListMenus(ctx context.Context) ([]AdminMenu, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Pool.Query(ctx, `SELECT id, menu_title, image_url, created_at FROM menus ORDER BY id`)
	if err != nil {
		return nil, fmt.Errorf("failed to list menus: %w", err)
	}
	defer rows.Close()

	var menus []AdminMenu
	for rows.Next() {
		var m AdminMenu
		if err := rows.Scan(&m.ID, &m.MenuTitle, &m.ImageURL, &m.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan menu: %w", err)
		}
		menus = append(menus, m)
	}

	return menus, rows.Err()
}

// CreateMenu inserts a new menu / category.
func (s *Service) CreateMenu(ctx context.Context, req *AdminMenuRequest) (*AdminMenu, error) {
	if req.MenuTitle == "" {
		return nil, fmt.Errorf("%w: menu_title is required", platform.ErrInvalidInput)
	}

	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var m AdminMenu
	err := s.db.Pool.QueryRow(ctx, `
		INSERT INTO menus (menu_title, image_url, created_at)
		VALUES ($1, $2, NOW())
		RETURNING id, menu_title, image_url, created_at
	`, req.MenuTitle, req.ImageURL).Scan(&m.ID, &m.MenuTitle, &m.ImageURL, &m.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create menu: %w", err)
	}

	s.invalidateCatalog(ctx)
	return &m, nil
}

// DeleteMenu removes a menu (items keep existing via ON DELETE SET NULL).
func (s *Service) DeleteMenu(ctx context.Context, menuID int64) error {
	if s.db == nil || s.db.Pool == nil {
		return platform.ErrInternal
	}

	tag, err := s.db.Pool.Exec(ctx, `DELETE FROM menus WHERE id = $1`, menuID)
	if err != nil {
		return fmt.Errorf("failed to delete menu: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return platform.ErrNotFound
	}

	s.invalidateCatalog(ctx)
	return nil
}

// ListDeals returns all daily deals.
func (s *Service) ListDeals(ctx context.Context) ([]AdminDeal, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Pool.Query(ctx, `
		SELECT id, title, description, (original_price * 100)::bigint, (deal_price * 100)::bigint, image_url, is_active, created_at
		FROM daily_deals ORDER BY created_at DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to list deals: %w", err)
	}
	defer rows.Close()

	var deals []AdminDeal
	for rows.Next() {
		var d AdminDeal
		var rawOrig, rawDeal int64
		if err := rows.Scan(
			&d.ID, &d.Title, &d.Description, &rawOrig, &rawDeal,
			&d.ImageURL, &d.IsActive, &d.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan deal: %w", err)
		}
		d.OriginalPrice = platform.FromPaise(rawOrig)
		d.DealPrice = platform.FromPaise(rawDeal)
		deals = append(deals, d)
	}

	return deals, rows.Err()
}

// CreateDeal inserts a new daily deal.
func (s *Service) CreateDeal(ctx context.Context, req *AdminDealRequest) (*AdminDeal, error) {
	if req.Title == "" || req.DealPrice <= 0 {
		return nil, fmt.Errorf("%w: title and deal_price are required", platform.ErrInvalidInput)
	}

	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	var d AdminDeal
	err := s.db.Pool.QueryRow(ctx, `
		INSERT INTO daily_deals (title, description, original_price, deal_price, image_url, is_active, created_at)
		VALUES ($1, $2, $3 / 100.0, $4 / 100.0, $5, $6, NOW())
		RETURNING id, title, description, (original_price * 100)::bigint, (deal_price * 100)::bigint, image_url, is_active, created_at
	`, req.Title, req.Description, req.OriginalPrice, req.DealPrice, req.ImageURL, isActive).Scan(
		&d.ID, &d.Title, &d.Description, &d.OriginalPrice, &d.DealPrice,
		&d.ImageURL, &d.IsActive, &d.CreatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create deal: %w", err)
	}

	s.invalidateCatalog(ctx)
	return &d, nil
}

// UpdateDeal updates an existing daily deal.
func (s *Service) UpdateDeal(ctx context.Context, dealID int64, req *AdminDealRequest) (*AdminDeal, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	tag, err := s.db.Pool.Exec(ctx, `
		UPDATE daily_deals SET
			title           = COALESCE(NULLIF($2, ''), title),
			description     = COALESCE(NULLIF($3, ''), description),
			original_price  = CASE WHEN $4 > 0 THEN $4 / 100.0 ELSE original_price END,
			deal_price      = CASE WHEN $5 > 0 THEN $5 / 100.0 ELSE deal_price END,
			image_url       = COALESCE(NULLIF($6, ''), image_url),
			is_active       = $7
		WHERE id = $1
	`, dealID, req.Title, req.Description, req.OriginalPrice, req.DealPrice,
		req.ImageURL, isActive)
	if err != nil {
		return nil, fmt.Errorf("failed to update deal: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, platform.ErrNotFound
	}

	s.invalidateCatalog(ctx)
	return s.GetDeal(ctx, dealID)
}

// DeleteDeal removes a daily deal.
func (s *Service) DeleteDeal(ctx context.Context, dealID int64) error {
	if s.db == nil || s.db.Pool == nil {
		return platform.ErrInternal
	}

	tag, err := s.db.Pool.Exec(ctx, `DELETE FROM daily_deals WHERE id = $1`, dealID)
	if err != nil {
		return fmt.Errorf("failed to delete deal: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return platform.ErrNotFound
	}

	s.invalidateCatalog(ctx)
	return nil
}

// GetDeal returns a single daily deal.
func (s *Service) GetDeal(ctx context.Context, dealID int64) (*AdminDeal, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var d AdminDeal
	var rawOrig, rawDeal int64
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id, title, description, (original_price * 100)::bigint, (deal_price * 100)::bigint, image_url, is_active, created_at
		FROM daily_deals WHERE id = $1
	`, dealID).Scan(
		&d.ID, &d.Title, &d.Description, &rawOrig, &rawDeal,
		&d.ImageURL, &d.IsActive, &d.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch deal: %w", err)
	}

	d.OriginalPrice = platform.FromPaise(rawOrig)
	d.DealPrice = platform.FromPaise(rawDeal)
	return &d, nil
}

// ---------------------------------------------------------------------------
// Pages (CMS)
// ---------------------------------------------------------------------------

// ListPages returns all CMS pages.
func (s *Service) ListPages(ctx context.Context) ([]Page, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Pool.Query(ctx, `SELECT id, slug, title, content, updated_at FROM pages ORDER BY id`)
	if err != nil {
		return nil, fmt.Errorf("failed to list pages: %w", err)
	}
	defer rows.Close()

	var pages []Page
	for rows.Next() {
		var p Page
		if err := rows.Scan(&p.ID, &p.Slug, &p.Title, &p.Content, &p.UpdatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan page: %w", err)
		}
		pages = append(pages, p)
	}

	return pages, rows.Err()
}

// UpsertPage creates or updates a CMS page by slug.
func (s *Service) UpsertPage(ctx context.Context, slug string, req *PageRequest) (*Page, error) {
	if req.Title == "" {
		return nil, fmt.Errorf("%w: title is required", platform.ErrInvalidInput)
	}

	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var p Page
	err := s.db.Pool.QueryRow(ctx, `
		INSERT INTO pages (slug, title, content, updated_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT (slug) DO UPDATE SET
			title      = EXCLUDED.title,
			content    = EXCLUDED.content,
			updated_at = NOW()
		RETURNING id, slug, title, content, updated_at
	`, slug, req.Title, req.Content).Scan(&p.ID, &p.Slug, &p.Title, &p.Content, &p.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to upsert page: %w", err)
	}

	return &p, nil
}

// DeletePage removes a CMS page.
func (s *Service) DeletePage(ctx context.Context, pageID int64) error {
	if s.db == nil || s.db.Pool == nil {
		return platform.ErrInternal
	}

	tag, err := s.db.Pool.Exec(ctx, `DELETE FROM pages WHERE id = $1`, pageID)
	if err != nil {
		return fmt.Errorf("failed to delete page: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return platform.ErrNotFound
	}

	return nil
}

// invalidateCatalog purges cached catalog keys after any catalog mutation.
func (s *Service) invalidateCatalog(ctx context.Context) {
	if s.cache == nil {
		return
	}
	if err := s.cache.DeletePattern(ctx, "catalog:*"); err != nil {
		// Cache invalidation failure should not fail the mutation; TTL self-heals.
		return
	}
}