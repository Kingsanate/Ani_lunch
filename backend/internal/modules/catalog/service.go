package catalog

import (
	"context"
	"fmt"
	"log/slog"
	"math/rand"
	"time"

	"animeat/backend/internal/cache"
	"animeat/backend/internal/database"
	"animeat/backend/internal/observability"
	"animeat/backend/internal/platform"
	"golang.org/x/sync/singleflight"
)

const (
	ItemsCacheTTL      = 5 * time.Minute
	DailyDealsCacheTTL = 15 * time.Minute
	MenusCacheTTL      = 10 * time.Minute
)

// jitterFactor is the maximum fraction applied to TTLs so that keys expire
// at slightly different times, preventing synchronized expiry stampedes.
const jitterFactor = 0.10

type Service struct {
	db    *database.Postgres
	cache *cache.RedisClient
	group singleflight.Group
}

func NewService(db *database.Postgres, cache *cache.RedisClient) *Service {
	return &Service{
		db:    db,
		cache: cache,
	}
}

// jitteredTTL returns a TTL randomized within ±jitterFactor of the base.
func jitteredTTL(base time.Duration) time.Duration {
	delta := float64(base) * jitterFactor
	offset := time.Duration(rand.Float64()*2*delta - delta)
	return base + offset
}

// cacheGet retrieves a cached value and records hit/miss metrics.
func (s *Service) cacheGet(ctx context.Context, key string, dest interface{}) bool {
	if s.cache == nil {
		return false
	}
	if err := s.cache.Get(ctx, key, dest); err == nil {
		observability.RecordCacheHit()
		return true
	}
	observability.RecordCacheMiss()
	return false
}

// cacheSet stores a value with a jittered TTL in the background.
func (s *Service) cacheSet(key string, data interface{}, baseTTL time.Duration) {
	if s.cache == nil {
		return
	}
	go func() {
		bgCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		if err := s.cache.Set(bgCtx, key, data, jitteredTTL(baseTTL)); err != nil {
			slog.Warn("failed to cache catalog data", "key", key, "error", err)
		}
	}()
}

// GetItems retrieves available food items with Cache-Aside acceleration and
// singleflight request coalescing (concurrent misses share one DB query).
func (s *Service) GetItems(ctx context.Context, category string) ([]Item, error) {
	cacheKey := "catalog:items:all"
	if category != "" {
		cacheKey = fmt.Sprintf("catalog:items:cat:%s", category)
	}

	var cachedItems []Item
	if s.cacheGet(ctx, cacheKey, &cachedItems) && len(cachedItems) > 0 {
		return cachedItems, nil
	}

	result, err, _ := s.group.Do(cacheKey, func() (interface{}, error) {
		return s.queryItems(ctx, category)
	})
	if err != nil {
		return nil, err
	}

	items := result.([]Item)
	if len(items) > 0 {
		s.cacheSet(cacheKey, items, ItemsCacheTTL)
	}
	return items, nil
}

func (s *Service) queryItems(ctx context.Context, category string) ([]Item, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	query := `
		SELECT id, vendor_id, name, description, price, original_price, 
		       category, image_url, is_available, preparation_min, rating, 
		       reviews_count, created_at, updated_at
		FROM items
		WHERE is_available = true
	`
	var rowsArgs []interface{}
	if category != "" {
		query += " AND category = $1"
		rowsArgs = append(rowsArgs, category)
	}
	query += " ORDER BY rating DESC, created_at DESC"

	rows, err := s.db.Reader().Query(ctx, query, rowsArgs...)
	if err != nil {
		return nil, fmt.Errorf("failed to query items: %w", err)
	}
	defer rows.Close()

	var items []Item
	for rows.Next() {
		var item Item
		var rawPrice int64
		var rawOrigPrice *int64

		err := rows.Scan(
			&item.ID, &item.VendorID, &item.Name, &item.Description,
			&rawPrice, &rawOrigPrice, &item.Category, &item.ImageURL,
			&item.IsAvailable, &item.PreparationMin, &item.Rating,
			&item.ReviewsCount, &item.CreatedAt, &item.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan item row: %w", err)
		}

		item.Price = platform.FromPaise(rawPrice)
		if rawOrigPrice != nil {
			item.OriginalPrice = platform.FromPaise(*rawOrigPrice)
		}

		items = append(items, item)
	}

	return items, rows.Err()
}

// GetMenus retrieves menu categories with Cache-Aside acceleration.
func (s *Service) GetMenus(ctx context.Context) ([]Menu, error) {
	cacheKey := "catalog:menus"

	var cachedMenus []Menu
	if s.cacheGet(ctx, cacheKey, &cachedMenus) && len(cachedMenus) > 0 {
		return cachedMenus, nil
	}

	result, err, _ := s.group.Do(cacheKey, func() (interface{}, error) {
		return s.queryMenus(ctx)
	})
	if err != nil {
		return nil, err
	}

	menus := result.([]Menu)
	if len(menus) > 0 {
		s.cacheSet(cacheKey, menus, MenusCacheTTL)
	}
	return menus, nil
}

func (s *Service) queryMenus(ctx context.Context) ([]Menu, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Reader().Query(ctx, `
		SELECT id, menu_title, image_url, created_at FROM menus ORDER BY id
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to query menus: %w", err)
	}
	defer rows.Close()

	var menus []Menu
	for rows.Next() {
		var m Menu
		var id int64
		if err := rows.Scan(&id, &m.MenuTitle, &m.ImageURL, &m.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan menu row: %w", err)
		}
		m.ID = fmt.Sprintf("%d", id)
		menus = append(menus, m)
	}

	return menus, rows.Err()
}

// GetDailyDeals retrieves active daily promotional deals with Cache-Aside
// acceleration and singleflight request coalescing.
func (s *Service) GetDailyDeals(ctx context.Context) ([]DailyDeal, error) {
	cacheKey := "catalog:daily_deals"

	var cachedDeals []DailyDeal
	if s.cacheGet(ctx, cacheKey, &cachedDeals) && len(cachedDeals) > 0 {
		return cachedDeals, nil
	}

	result, err, _ := s.group.Do(cacheKey, func() (interface{}, error) {
		return s.queryDailyDeals(ctx)
	})
	if err != nil {
		return nil, err
	}

	deals := result.([]DailyDeal)
	if len(deals) > 0 {
		s.cacheSet(cacheKey, deals, DailyDealsCacheTTL)
	}
	return deals, nil
}

func (s *Service) queryDailyDeals(ctx context.Context) ([]DailyDeal, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	now := time.Now().UTC()
	rows, err := s.db.Reader().Query(ctx, `
		SELECT id, title, description, discount_percentage, max_discount_amount,
		       banner_image_url, valid_from, valid_until, is_active
		FROM daily_deals
		WHERE is_active = true AND valid_from <= $1 AND valid_until >= $1
		ORDER BY discount_percentage DESC
	`, now)
	if err != nil {
		return nil, fmt.Errorf("failed to query daily deals: %w", err)
	}
	defer rows.Close()

	var deals []DailyDeal
	for rows.Next() {
		var deal DailyDeal
		var rawMaxDiscount int64

		err := rows.Scan(
			&deal.ID, &deal.Title, &deal.Description,
			&deal.DiscountPct, &rawMaxDiscount, &deal.BannerImageURL,
			&deal.ValidFrom, &deal.ValidUntil, &deal.IsActive,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan deal row: %w", err)
		}

		deal.MaxDiscountAmt = platform.FromPaise(rawMaxDiscount)
		deals = append(deals, deal)
	}

	return deals, rows.Err()
}

// InvalidateCatalog purges all catalog cache keys upon database mutations.
func (s *Service) InvalidateCatalog(ctx context.Context) error {
	if s.cache == nil {
		return nil
	}
	return s.cache.DeletePattern(ctx, "catalog:*")
}
