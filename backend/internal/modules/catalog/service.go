package catalog

import (
	"context"
	"fmt"
	"log/slog"
	"math/rand"
	"strings"
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
		return defaultSeedItems(category), nil
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
		return defaultSeedItems(category), nil
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
			return defaultSeedItems(category), nil
		}

		item.Price = platform.FromPaise(rawPrice)
		if rawOrigPrice != nil {
			item.OriginalPrice = platform.FromPaise(*rawOrigPrice)
		}

		items = append(items, item)
	}

	if len(items) == 0 {
		return defaultSeedItems(category), nil
	}

	return items, nil
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
		return defaultSeedMenus(), nil
	}

	menus := result.([]Menu)
	if len(menus) > 0 {
		s.cacheSet(cacheKey, menus, MenusCacheTTL)
	}
	return menus, nil
}

func (s *Service) queryMenus(ctx context.Context) ([]Menu, error) {
	if s.db == nil || s.db.Reader() == nil {
		return defaultSeedMenus(), nil
	}

	rows, err := s.db.Reader().Query(ctx, `
		SELECT id, menu_title, image_url, created_at FROM menus ORDER BY id
	`)
	if err != nil {
		return defaultSeedMenus(), nil
	}
	defer rows.Close()

	var menus []Menu
	for rows.Next() {
		var m Menu
		var id int64
		if err := rows.Scan(&id, &m.MenuTitle, &m.ImageURL, &m.CreatedAt); err != nil {
			return defaultSeedMenus(), nil
		}
		m.ID = fmt.Sprintf("%d", id)
		menus = append(menus, m)
	}

	if len(menus) == 0 {
		return defaultSeedMenus(), nil
	}

	return menus, nil
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
		return defaultSeedDeals(), nil
	}

	deals := result.([]DailyDeal)
	if len(deals) > 0 {
		s.cacheSet(cacheKey, deals, DailyDealsCacheTTL)
	}
	return deals, nil
}

func (s *Service) queryDailyDeals(ctx context.Context) ([]DailyDeal, error) {
	if s.db != nil && s.db.Reader() != nil {
		rows, err := s.db.Reader().Query(ctx, `
			SELECT id::text, title, COALESCE(description, ''),
			       COALESCE(discount_percentage, discount, 0),
			       COALESCE((max_discount_amount * 100)::bigint, 0),
			       COALESCE(banner_image_url, image_url, ''),
			       COALESCE(valid_from, NOW() - INTERVAL '1 day'),
			       COALESCE(valid_until, NOW() + INTERVAL '365 days'),
			       COALESCE(is_active, true)
			FROM daily_deals
			WHERE is_active = true
			ORDER BY id DESC
		`)
		if err == nil {
			defer rows.Close()
			var deals []DailyDeal
			for rows.Next() {
				var deal DailyDeal
				var rawMaxDiscount int64

				if err := rows.Scan(
					&deal.ID, &deal.Title, &deal.Description,
					&deal.DiscountPct, &rawMaxDiscount, &deal.BannerImageURL,
					&deal.ValidFrom, &deal.ValidUntil, &deal.IsActive,
				); err == nil {
					deal.MaxDiscountAmt = platform.FromPaise(rawMaxDiscount)
					deals = append(deals, deal)
				}
			}
			if len(deals) > 0 {
				return deals, nil
			}
		}
	}

	stored := platform.GlobalStore.ListDeals()
	deals := make([]DailyDeal, 0, len(stored))
	for _, d := range stored {
		if d.IsActive {
			desc := d.Description
			img := d.BannerImageURL
			deals = append(deals, DailyDeal{
				ID:             fmt.Sprintf("%d", d.ID),
				Title:          d.Title,
				Description:    &desc,
				DiscountPct:    d.DiscountPct,
				MaxDiscountAmt: d.OriginalPrice,
				BannerImageURL: &img,
				IsActive:       d.IsActive,
				ValidFrom:      d.CreatedAt.Add(-24 * time.Hour),
				ValidUntil:     d.CreatedAt.Add(365 * 24 * time.Hour),
			})
		}
	}
	return deals, nil
}

func defaultSeedMenus() []Menu {
	heroImg := "assets/images/hero.png"
	return []Menu{
		{ID: "meal", MenuTitle: "Meal / Lunch", ImageURL: &heroImg, CreatedAt: time.Now()},
		{ID: "chicken", MenuTitle: "Chicken", ImageURL: &heroImg, CreatedAt: time.Now()},
		{ID: "mutton", MenuTitle: "Mutton", ImageURL: &heroImg, CreatedAt: time.Now()},
		{ID: "fish", MenuTitle: "Fish & Seafood", ImageURL: &heroImg, CreatedAt: time.Now()},
		{ID: "eggs", MenuTitle: "Eggs", ImageURL: &heroImg, CreatedAt: time.Now()},
	}
}

func defaultSeedItems(category string) []Item {
	descChicken := "Tender, skinless & boneless chicken breast cut."
	imgChicken := "https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=600&q=80"
	descMutton := "Rich goat curry cut from fresh meat."
	imgMutton := "https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80"
	descSalmon := "Fresh Atlantic salmon fillet cut."
	imgSalmon := "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&q=80"

	all := []Item{
		{ID: "ch_1", Name: "Fresh Chicken Breast (500g)", Description: &descChicken, Price: platform.FromPaise(24000), Category: "chicken", ImageURL: &imgChicken, IsAvailable: true, Rating: 4.8, ReviewsCount: 142},
		{ID: "mu_1", Name: "Rich Goat Curry Cut (500g)", Description: &descMutton, Price: platform.FromPaise(48000), Category: "mutton", ImageURL: &imgMutton, IsAvailable: true, Rating: 4.9, ReviewsCount: 98},
		{ID: "fi_1", Name: "Fresh Salmon Fillet (300g)", Description: &descSalmon, Price: platform.FromPaise(52000), Category: "fish", ImageURL: &imgSalmon, IsAvailable: true, Rating: 4.7, ReviewsCount: 65},
	}

	if category == "" || category == "all" {
		return all
	}
	var filtered []Item
	for _, it := range all {
		if it.Category == category {
			filtered = append(filtered, it)
		}
	}
	return filtered
}

func defaultSeedDeals() []DailyDeal {
	desc := "Flat 20% OFF on all lunch orders today"
	img := "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80"
	return []DailyDeal{
		{
			ID:             "deal_1",
			Title:          "Weekend Lunch Feast",
			Description:    &desc,
			DiscountPct:    20,
			MaxDiscountAmt: platform.FromPaise(10000),
			BannerImageURL: &img,
			IsActive:       true,
			ValidFrom:      time.Now().Add(-24 * time.Hour),
			ValidUntil:     time.Now().Add(48 * time.Hour),
		},
	}
}

// GetMealProducts retrieves lunch thalis and meals.
func (s *Service) GetMealProducts(ctx context.Context) ([]MealProduct, error) {
	if s.db == nil || s.db.Reader() == nil {
		return defaultMealProducts(), nil
	}

	rows, err := s.db.Reader().Query(ctx, `
		SELECT id::text, name, COALESCE(description, ''), price, discount_price, COALESCE(rating, 0), COALESCE(image_url, ''), is_available, COALESCE(rice_options, '{}'), COALESCE(meat_options, '{}'), created_at
		FROM meal_products
		WHERE is_available = true
		ORDER BY created_at DESC
	`)
	if err != nil {
		return defaultMealProducts(), nil
	}
	defer rows.Close()

	var products []MealProduct
	existing := make(map[string]bool)
	for rows.Next() {
		var p MealProduct
		if err := rows.Scan(
			&p.ID, &p.Name, &p.Description, &p.Price, &p.DiscountPrice, &p.Rating, &p.ImageURL, &p.IsAvailable, &p.RiceOptions, &p.MeatOptions, &p.CreatedAt,
		); err == nil {
			products = append(products, p)
			existing[strings.ToLower(p.Name)] = true
		}
	}

	for _, def := range defaultMealProducts() {
		if !existing[strings.ToLower(def.Name)] {
			products = append(products, def)
		}
	}

	return products, nil
}

// GetAppSettings retrieves global application settings.
func (s *Service) GetAppSettings(ctx context.Context) (*AppSettings, error) {
	if s.db == nil || s.db.Reader() == nil {
		return &AppSettings{
			ID: "default", AppName: "AniLunch", ContactEmail: "support@anilunch.com", ContactPhone: "+91 9774164689", DeliveryFee: 30, FreeDeliveryThreshold: 500, IsStoreOpen: true,
		}, nil
	}

	var st AppSettings
	err := s.db.Reader().QueryRow(ctx, `
		SELECT id::text, COALESCE(app_name, 'AniLunch'), COALESCE(contact_email, ''), COALESCE(contact_phone, ''), COALESCE(delivery_fee, 30), COALESCE(free_delivery_threshold, 500), COALESCE(is_store_open, true)
		FROM app_settings
		LIMIT 1
	`).Scan(&st.ID, &st.AppName, &st.ContactEmail, &st.ContactPhone, &st.DeliveryFee, &st.FreeDeliveryThreshold, &st.IsStoreOpen)
	if err != nil {
		return &AppSettings{
			ID: "default", AppName: "AniLunch", ContactEmail: "support@anilunch.com", ContactPhone: "+91 9774164689", DeliveryFee: 30, FreeDeliveryThreshold: 500, IsStoreOpen: true,
		}, nil
	}
	return &st, nil
}

func defaultMealProducts() []MealProduct {
	return []MealProduct{
		{
			ID: "50e91272-8541-4e4b-af57-5f2a51c2dd69", Name: "Khasi Thali", Description: "Pure Local Traditional Platter", Price: 200, Rating: 4.9,
			ImageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80", IsAvailable: true,
			RiceOptions: []string{"White Rice", "Red Rice"}, MeatOptions: []string{"Chicken", "Pork", "Beef", "Fish"}, CreatedAt: time.Now(),
		},
		{
			ID: "mizo-thali-7788-9900", Name: "Mizo Thali", Description: "Authentic Tribal Lunch & Bai", Price: 200, Rating: 4.9,
			ImageURL: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&q=80", IsAvailable: true,
			RiceOptions: []string{"Steamed Local Rice"}, MeatOptions: []string{"Smoked Pork", "Boiled Chicken", "Local Fish"}, CreatedAt: time.Now(),
		},
		{
			ID: "naga-thali-3344-5566", Name: "Naga Thali", Description: "Smoked Meat with Bamboo Shoot", Price: 200, Rating: 4.9,
			ImageURL: "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&q=80", IsAvailable: true,
			RiceOptions: []string{"Naga Sticky Rice", "White Rice"}, MeatOptions: []string{"Smoked Pork & Axone", "Spicy Chicken Curry"}, CreatedAt: time.Now(),
		},
		{
			ID: "001e758c-d57b-4310-9131-e0947019c517", Name: "Indian Thali", Description: "Classic North Indian Meal", Price: 150, Rating: 4.8,
			ImageURL: "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&q=80", IsAvailable: true,
			RiceOptions: []string{"Jeera Rice", "Plain Rice"}, MeatOptions: []string{"Chicken Curry", "Mutton Curry"}, CreatedAt: time.Now(),
		},
	}
}

// InvalidateCatalog purges all catalog cache keys upon database mutations.
func (s *Service) InvalidateCatalog(ctx context.Context) error {
	if s.cache == nil {
		return nil
	}
	return s.cache.DeletePattern(ctx, "catalog:*")
}
