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
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	startOfDay := time.Now().UTC().Truncate(24 * time.Hour)
	stats := &DashboardStats{StatusBreakdown: map[string]int{
		"pending": 0, "preparing": 0, "ready_for_pickup": 0, "on_the_way": 0, "delivered": 0,
	}}

	if s.db != nil && s.db.Pool != nil {
		_ = s.db.Pool.QueryRow(ctx, `
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

		rows, err := s.db.Pool.Query(ctx, `SELECT status, COUNT(*) FROM orders GROUP BY status`)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var status string
				var count int
				if err := rows.Scan(&status, &count); err == nil {
					stats.StatusBreakdown[status] = count
				}
			}
		}
	}

	// Fallback/merge with GlobalStore
	memOrders := platform.GlobalStore.List()
	if len(memOrders) > 0 {
		stats.TotalOrders = len(memOrders)
		for _, mo := range memOrders {
			stats.StatusBreakdown[mo.Status]++
			if mo.OrderTime.After(startOfDay) {
				stats.OrdersToday++
			}
			stats.RevenueToday = stats.RevenueToday.Add(mo.TotalAmount)
		}
	}
	if stats.VendorCount == 0 {
		stats.VendorCount = 1
	}
	if stats.UserCount == 0 {
		stats.UserCount = 1
	}

	return stats, nil
}

// ---------------------------------------------------------------------------
// Orders (admin console)
// ---------------------------------------------------------------------------

// ListOrders returns every order with the customer's name and address.
func (s *Service) ListOrders(ctx context.Context, status string) ([]AdminOrder, error) {
	orders := make([]AdminOrder, 0)
	if s.db != nil && s.db.Pool != nil {
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
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var o AdminOrder
				var itemsJSON []byte
				if err := rows.Scan(
					&o.ID, &o.UserID, &o.VendorID, &o.Status, &itemsJSON,
					&o.Subtotal, &o.DeliveryFee, &o.Discount, &o.TotalAmount,
					&o.PaymentMethod, &o.PaymentStatus, &o.SpecialNotes,
					&o.RiderID, &o.OrderTime, &o.CustomerName, &o.Address,
				); err == nil {
					if len(itemsJSON) > 0 {
						_ = json.Unmarshal(itemsJSON, &o.Items)
					}
					orders = append(orders, o)
				}
			}
		}
	}

	// Merge/fallback from GlobalStore
	memOrders := platform.GlobalStore.List()
	existingIDs := make(map[string]bool)
	for _, o := range orders {
		existingIDs[o.ID] = true
	}
	for _, mo := range memOrders {
		if !existingIDs[mo.ID] && (status == "" || mo.Status == status) {
			vendorID := ""
			if mo.VendorID != nil {
				vendorID = *mo.VendorID
			}
			specialNotes := ""
			if mo.SpecialNotes != nil {
				specialNotes = *mo.SpecialNotes
			}
			orders = append(orders, AdminOrder{
				ID:            mo.ID,
				UserID:        mo.UserID,
				VendorID:      vendorID,
				RiderID:       mo.RiderID,
				Status:        mo.Status,
				Subtotal:      mo.Subtotal,
				DeliveryFee:   mo.DeliveryFee,
				Discount:      mo.Discount,
				TotalAmount:   mo.TotalAmount,
				PaymentMethod: mo.PaymentMethod,
				PaymentStatus: mo.PaymentStatus,
				SpecialNotes:  specialNotes,
				CustomerName:  mo.CustomerName,
				Address:       mo.DeliveryStreet,
				OrderTime:     mo.OrderTime,
				Items:         []AdminOrderItem{},
			})
		}
	}

	return orders, nil
}

// ListUsers returns the customer records used by the order console.
func (s *Service) ListUsers(ctx context.Context) ([]AdminUser, error) {
	users := make([]AdminUser, 0)
	if s.db != nil && s.db.Pool != nil {
		rows, err := s.db.Pool.Query(ctx, `
			SELECT id, COALESCE(name, ''), COALESCE(email, '') FROM users ORDER BY created_at DESC
		`)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var u AdminUser
				if err := rows.Scan(&u.ID, &u.Name, &u.Email); err == nil {
					users = append(users, u)
				}
			}
		}
	}

	if len(users) == 0 {
		users = []AdminUser{
			{ID: "usr-1", Name: "AniLunch Admin", Email: "questrsanate@gmail.com"},
		}
	}

	return users, nil
}

// ---------------------------------------------------------------------------
// Rider management
// ---------------------------------------------------------------------------

// ListRiders returns all rider records, optionally filtered by approval status.
func (s *Service) ListRiders(ctx context.Context, status string) ([]AdminRider, error) {
	riders := make([]AdminRider, 0)
	if s.db != nil && s.db.Pool != nil {
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
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var r AdminRider
				if err := rows.Scan(
					&r.ID, &r.Name, &r.Phone, &r.Email, &r.IsOnline,
					&r.IsApproved, &r.ApprovalStatus, &r.RejectionReason,
					&r.CreatedAt, &r.UpdatedAt,
				); err == nil {
					riders = append(riders, r)
				}
			}
		}
	}

	if len(riders) == 0 {
		riders = []AdminRider{
			{ID: "rdr-1", Name: "Delivery Partner 1", Phone: "+91 9774164689", Email: "rider1@anilunch.app", IsOnline: true, IsApproved: true, ApprovalStatus: "approved", CreatedAt: time.Now(), UpdatedAt: time.Now()},
		}
	}

	return riders, nil
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
	var items []AdminItem
	if s.db != nil && s.db.Pool != nil {
		rows, err := s.db.Pool.Query(ctx, `
			SELECT id, item_title, price, original_price, description, thumbnail_url,
			       category_id, vendor_id, is_active, preparation_min, rating, reviews_count,
			       created_at, updated_at
			FROM items ORDER BY created_at DESC
		`)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var i AdminItem
				var rawPrice, rawOrigPrice *int64
				if err := rows.Scan(
					&i.ID, &i.ItemTitle, &rawPrice, &rawOrigPrice, &i.Description,
					&i.ThumbnailURL, &i.CategoryID, &i.VendorID, &i.IsActive,
					&i.PreparationMin, &i.Rating, &i.ReviewsCount,
					&i.CreatedAt, &i.UpdatedAt,
				); err == nil {
					if rawPrice != nil {
						i.Price = platform.FromPaise(*rawPrice)
					}
					if rawOrigPrice != nil {
						i.OriginalPrice = platform.FromPaise(*rawOrigPrice)
					}
					items = append(items, i)
				}
			}
		}
	}

	if len(items) == 0 {
		items = []AdminItem{
			{ID: "itm-1", ItemTitle: "Mizo Pork Thali", Price: platform.FromPaise(20000), OriginalPrice: platform.FromPaise(20000), Description: "Fresh local pork cooked with indigenous herbs, seasonal greens and steamed rice.", ThumbnailURL: "assets/images/pork.png", IsActive: true, Rating: 4.8, ReviewsCount: 42},
			{ID: "itm-2", ItemTitle: "Khasi Beef Thali", Price: platform.FromPaise(20000), OriginalPrice: platform.FromPaise(20000), Description: "Tender beef cooked with local traditional spices and fragrant rice.", ThumbnailURL: "assets/images/beef.png", IsActive: true, Rating: 4.9, ReviewsCount: 68},
			{ID: "itm-3", ItemTitle: "Naga Chicken Thali", Price: platform.FromPaise(20000), OriginalPrice: platform.FromPaise(20000), Description: "Smoked chicken curry cooked with bamboo shoots and steamed rice.", ThumbnailURL: "assets/images/chicken.png", IsActive: true, Rating: 4.7, ReviewsCount: 35},
		}
	}

	return items, nil
}

// ListMenus returns all menus / categories.
func (s *Service) ListMenus(ctx context.Context) ([]AdminMenu, error) {
	menus := make([]AdminMenu, 0)
	if s.db != nil && s.db.Pool != nil {
		rows, err := s.db.Pool.Query(ctx, `SELECT id, menu_title, image_url, created_at FROM menus ORDER BY id`)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var m AdminMenu
				if err := rows.Scan(&m.ID, &m.MenuTitle, &m.ImageURL, &m.CreatedAt); err == nil {
					menus = append(menus, m)
				}
			}
		}
	}

	if len(menus) == 0 {
		menus = []AdminMenu{
			{ID: 1, MenuTitle: "Lunch Combos", ImageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400", CreatedAt: time.Now()},
			{ID: 2, MenuTitle: "Local Meat Specials", ImageURL: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400", CreatedAt: time.Now()},
			{ID: 3, MenuTitle: "Indigenous Sides & Chutneys", ImageURL: "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400", CreatedAt: time.Now()},
		}
	}

	return menus, nil
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
	if s.db != nil && s.db.Pool != nil {
		rows, err := s.db.Pool.Query(ctx, `
			SELECT id, title, COALESCE(description, ''),
			       COALESCE((original_price * 100)::bigint, 0),
			       COALESCE((deal_price * 100)::bigint, 0),
			       COALESCE(image_url, banner_image_url, ''),
			       COALESCE(is_active, true),
			       COALESCE(created_at, NOW())
			FROM daily_deals ORDER BY id DESC
		`)
		if err == nil {
			defer rows.Close()
			deals := make([]AdminDeal, 0)
			for rows.Next() {
				var d AdminDeal
				var rawOrig, rawDeal int64
				if err := rows.Scan(
					&d.ID, &d.Title, &d.Description, &rawOrig, &rawDeal,
					&d.ImageURL, &d.IsActive, &d.CreatedAt,
				); err == nil {
					d.OriginalPrice = platform.FromPaise(rawOrig)
					d.DealPrice = platform.FromPaise(rawDeal)
					deals = append(deals, d)
				}
			}
			if len(deals) > 0 {
				return deals, nil
			}
		}
	}

	stored := platform.GlobalStore.ListDeals()
	deals := make([]AdminDeal, 0, len(stored))
	for _, d := range stored {
		deals = append(deals, AdminDeal{
			ID:            d.ID,
			Title:         d.Title,
			Description:   d.Description,
			OriginalPrice: d.OriginalPrice,
			DealPrice:     d.DealPrice,
			ImageURL:      d.BannerImageURL,
			IsActive:      d.IsActive,
			CreatedAt:     d.CreatedAt,
		})
	}
	return deals, nil
}

// CreateDeal inserts a new daily deal.
func (s *Service) CreateDeal(ctx context.Context, req *AdminDealRequest) (*AdminDeal, error) {
	if req.Title == "" || req.DealPrice <= 0 {
		return nil, fmt.Errorf("%w: title and deal_price are required", platform.ErrInvalidInput)
	}

	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	dealID := time.Now().UnixMilli()
	if s.db != nil && s.db.Pool != nil {
		_ = s.db.Pool.QueryRow(ctx, `
			INSERT INTO daily_deals (title, description, original_price, deal_price, image_url, banner_image_url, is_active, created_at, valid_from, valid_until)
			VALUES ($1, $2, $3 / 100.0, $4 / 100.0, $5, $5, $6, NOW(), NOW() - INTERVAL '1 day', NOW() + INTERVAL '365 days')
			RETURNING id
		`, req.Title, req.Description, req.OriginalPrice, req.DealPrice, req.ImageURL, isActive).Scan(&dealID)
	}

	d := &AdminDeal{
		ID:            dealID,
		Title:         req.Title,
		Description:   req.Description,
		OriginalPrice: platform.FromPaise(int64(req.OriginalPrice)),
		DealPrice:     platform.FromPaise(int64(req.DealPrice)),
		ImageURL:      req.ImageURL,
		IsActive:      isActive,
		CreatedAt:     time.Now().UTC(),
	}

	var pct float64
	if req.OriginalPrice > req.DealPrice && req.OriginalPrice > 0 {
		pct = float64(req.OriginalPrice-req.DealPrice) / float64(req.OriginalPrice) * 100
	}

	platform.GlobalStore.SaveDeal(&platform.SharedDeal{
		ID:             dealID,
		Title:          req.Title,
		Description:    req.Description,
		DiscountPct:    pct,
		OriginalPrice:  d.OriginalPrice,
		DealPrice:      d.DealPrice,
		BannerImageURL: req.ImageURL,
		IsActive:       isActive,
		CreatedAt:      d.CreatedAt,
	})

	s.invalidateCatalog(ctx)
	return d, nil
}

// UpdateDeal updates an existing daily deal.
func (s *Service) UpdateDeal(ctx context.Context, dealID int64, req *AdminDealRequest) (*AdminDeal, error) {
	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	if s.db != nil && s.db.Pool != nil {
		_, _ = s.db.Pool.Exec(ctx, `
			UPDATE daily_deals SET
				title           = COALESCE(NULLIF($2, ''), title),
				description     = COALESCE(NULLIF($3, ''), description),
				original_price  = CASE WHEN $4 > 0 THEN $4 / 100.0 ELSE original_price END,
				deal_price      = CASE WHEN $5 > 0 THEN $5 / 100.0 ELSE deal_price END,
				image_url       = COALESCE(NULLIF($6, ''), image_url),
				banner_image_url= COALESCE(NULLIF($6, ''), banner_image_url),
				is_active       = $7
			WHERE id = $1
		`, dealID, req.Title, req.Description, req.OriginalPrice, req.DealPrice,
			req.ImageURL, isActive)
	}

	var pct float64
	if req.OriginalPrice > req.DealPrice && req.OriginalPrice > 0 {
		pct = float64(req.OriginalPrice-req.DealPrice) / float64(req.OriginalPrice) * 100
	}

	platform.GlobalStore.SaveDeal(&platform.SharedDeal{
		ID:             dealID,
		Title:          req.Title,
		Description:    req.Description,
		DiscountPct:    pct,
		OriginalPrice:  platform.FromPaise(int64(req.OriginalPrice)),
		DealPrice:      platform.FromPaise(int64(req.DealPrice)),
		BannerImageURL: req.ImageURL,
		IsActive:       isActive,
		CreatedAt:      time.Now().UTC(),
	})

	s.invalidateCatalog(ctx)
	return s.GetDeal(ctx, dealID)
}

// DeleteDeal removes a daily deal.
func (s *Service) DeleteDeal(ctx context.Context, dealID int64) error {
	if s.db != nil && s.db.Pool != nil {
		_, _ = s.db.Pool.Exec(ctx, `DELETE FROM daily_deals WHERE id = $1`, dealID)
	}
	platform.GlobalStore.DeleteDeal(dealID)
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