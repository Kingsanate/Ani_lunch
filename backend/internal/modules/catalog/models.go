package catalog

import (
	"time"

	"animeat/backend/internal/platform"
)

// Item represents a menu catalog food item.
type Item struct {
	ID             string         `json:"id"`
	VendorID       *string        `json:"vendor_id,omitempty"`
	Name           string         `json:"name"`
	Description    *string        `json:"description,omitempty"`
	Price          platform.Money `json:"price"` // Stored in paise
	OriginalPrice  platform.Money `json:"original_price,omitempty"`
	Category       string         `json:"category"`
	ImageURL       *string        `json:"image_url,omitempty"`
	IsAvailable    bool           `json:"is_available"`
	PreparationMin int            `json:"preparation_min"`
	Rating         float64        `json:"rating"`
	ReviewsCount   int            `json:"reviews_count"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// Menu represents a menu / category entry.
type Menu struct {
	ID        string    `json:"id"`
	MenuTitle string    `json:"menu_title"`
	ImageURL  *string   `json:"image_url,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// DailyDeal represents promotional banners and discounts.
type DailyDeal struct {
	ID             string         `json:"id"`
	Title          string         `json:"title"`
	Description    *string        `json:"description,omitempty"`
	DiscountPct    float64        `json:"discount_percent"`
	MaxDiscountAmt platform.Money `json:"max_discount_amount"`
	BannerImageURL *string        `json:"banner_image_url,omitempty"`
	ValidFrom      time.Time      `json:"valid_from"`
	ValidUntil     time.Time      `json:"valid_until"`
	IsActive       bool           `json:"is_active"`
}

// Coupon represents discount vouchers.
type Coupon struct {
	Code           string         `json:"code"`
	DiscountType   string         `json:"discount_type"` // 'percent' or 'fixed'
	DiscountValue  float64        `json:"discount_value"`
	MinOrderAmount platform.Money `json:"min_order_amount"`
	MaxDiscount    platform.Money `json:"max_discount"`
	ValidUntil     time.Time      `json:"valid_until"`
	IsActive       bool           `json:"is_active"`
}

// MealProduct represents lunch thalis and meals.
type MealProduct struct {
	ID            string    `json:"id"`
	Name          string    `json:"name"`
	Description   string    `json:"description"`
	Price         float64   `json:"price"`
	DiscountPrice *float64  `json:"discount_price,omitempty"`
	Rating        float64   `json:"rating"`
	ImageURL      string    `json:"image_url"`
	IsAvailable   bool      `json:"is_available"`
	RiceOptions   []string  `json:"rice_options"`
	MeatOptions   []string  `json:"meat_options"`
	CreatedAt     time.Time `json:"created_at"`
}

// AppSettings represents global platform settings.
type AppSettings struct {
	ID                    string `json:"id"`
	AppName               string `json:"app_name"`
	ContactEmail          string `json:"contact_email"`
	ContactPhone          string `json:"contact_phone"`
	DeliveryFee           int64  `json:"delivery_fee"`
	FreeDeliveryThreshold int64  `json:"free_delivery_threshold"`
	IsStoreOpen           bool   `json:"is_store_open"`
}
