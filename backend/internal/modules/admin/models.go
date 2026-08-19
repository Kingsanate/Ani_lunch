package admin

import (
	"time"

	"animeat/backend/internal/platform"
)

// DashboardStats is the platform-wide operational overview.
type DashboardStats struct {
	OrdersToday      int            `json:"orders_today"`
	RevenueToday     platform.Money `json:"revenue_today"`
	TotalOrders      int            `json:"total_orders"`
	ActiveRiders     int            `json:"active_riders"`
	PendingApprovals int            `json:"pending_rider_approvals"`
	VendorCount      int            `json:"vendor_count"`
	ItemCount        int            `json:"item_count"`
	UserCount        int            `json:"user_count"`
	StatusBreakdown  map[string]int `json:"status_breakdown"`
}

// AdminOrder is the full order projection used by the admin console.
type AdminOrder struct {
	ID            string         `json:"id"`
	UserID        string         `json:"user_id"`
	VendorID      string         `json:"vendor_id"`
	Status        string         `json:"status"`
	Items         []AdminOrderItem `json:"items"`
	Subtotal      platform.Money `json:"subtotal"`
	DeliveryFee   platform.Money `json:"delivery_fee"`
	Discount      platform.Money `json:"discount"`
	TotalAmount   platform.Money `json:"total_amount"`
	PaymentMethod string         `json:"payment_method"`
	PaymentStatus string         `json:"payment_status"`
	SpecialNotes  string         `json:"special_notes,omitempty"`
	RiderID       *string        `json:"rider_id,omitempty"`
	OrderTime     time.Time      `json:"order_time"`
	CustomerName  string         `json:"customer_name,omitempty"`
	Address       string         `json:"address,omitempty"`
}

// AdminOrderItem is the minimal item projection inside admin order views.
type AdminOrderItem struct {
	ID        string         `json:"id"`
	ItemID    string         `json:"item_id"`
	Name      string         `json:"name"`
	Quantity  int            `json:"quantity"`
	UnitPrice platform.Money `json:"unit_price"`
	Subtotal  platform.Money `json:"subtotal"`
}

// AdminUser is the customer record as seen by administrators.
type AdminUser struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

// AdminRider is the rider record as seen by administrators.
type AdminRider struct {
	ID              string    `json:"id"`
	Name            string    `json:"name"`
	Phone           string    `json:"phone"`
	Email           string    `json:"email"`
	IsOnline        bool      `json:"is_online"`
	IsApproved      bool      `json:"is_approved"`
	ApprovalStatus  string    `json:"approval_status"`
	RejectionReason *string   `json:"rejection_reason,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// RiderApprovalRequest approves or rejects a rider application.
type RiderApprovalRequest struct {
	ApprovalStatus  string  `json:"approval_status"` // approved | rejected
	RejectionReason *string `json:"rejection_reason,omitempty"`
}

// AppSettings is the dynamic branding & configuration singleton.
type AppSettings struct {
	ID                 int64   `json:"id"`
	HomeVideoURL       *string `json:"home_video_url,omitempty"`
	ShowHeroBanner     bool    `json:"show_hero_banner"`
	HeroBadgeText      string  `json:"hero_badge_text"`
	HeroTitle          string  `json:"hero_title"`
	HeroSubtitle       string  `json:"hero_subtitle"`
	HeroButtonText     string  `json:"hero_button_text"`
	FooterSubtitle     string  `json:"footer_subtitle"`
	FooterSupportLinks string  `json:"footer_support_links"`
	FooterLegalLinks   string  `json:"footer_legal_links"`
	FooterCopyright    string  `json:"footer_copyright"`
	UpdatedAt          *time.Time `json:"updated_at,omitempty"`
}

// AdminItem is the catalog item record as managed by administrators.
type AdminItem struct {
	ID             string         `json:"id"`
	ItemTitle      string         `json:"item_title"`
	Price          platform.Money `json:"price"`
	OriginalPrice  platform.Money `json:"original_price,omitempty"`
	Description    string         `json:"description"`
	ThumbnailURL   string         `json:"thumbnail_url,omitempty"`
	CategoryID     *int64         `json:"category_id,omitempty"`
	VendorID       *string        `json:"vendor_id,omitempty"`
	IsActive       bool           `json:"is_active"`
	PreparationMin int            `json:"preparation_min"`
	Rating         float64        `json:"rating"`
	ReviewsCount   int            `json:"reviews_count"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// AdminItemRequest is the payload for item create/update.
type AdminItemRequest struct {
	ItemTitle      string   `json:"item_title"`
	Price          int64    `json:"price"` // in paise
	OriginalPrice  *int64   `json:"original_price,omitempty"`
	Description    string   `json:"description"`
	ThumbnailURL   string   `json:"thumbnail_url"`
	CategoryID     *int64   `json:"category_id"`
	VendorID       *string  `json:"vendor_id"`
	IsActive       *bool    `json:"is_active"`
	PreparationMin *int     `json:"preparation_min"`
}

// AdminMenu is a menu / category entry.
type AdminMenu struct {
	ID        int64     `json:"id"`
	MenuTitle string    `json:"menu_title"`
	ImageURL  string    `json:"image_url,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// AdminMenuRequest is the payload for menu create/update.
type AdminMenuRequest struct {
	MenuTitle string `json:"menu_title"`
	ImageURL  string `json:"image_url"`
}

// AdminDeal is a daily deal / promotion entry.
type AdminDeal struct {
	ID            int64          `json:"id"`
	Title         string         `json:"title"`
	Description   string         `json:"description,omitempty"`
	OriginalPrice platform.Money `json:"original_price"`
	DealPrice     platform.Money `json:"deal_price"`
	ImageURL      string         `json:"image_url,omitempty"`
	IsActive      bool           `json:"is_active"`
	CreatedAt     time.Time      `json:"created_at"`
}

// AdminDealRequest is the payload for deal create/update.
type AdminDealRequest struct {
	Title         string `json:"title"`
	Description   string `json:"description"`
	OriginalPrice int64  `json:"original_price"` // in paise
	DealPrice     int64  `json:"deal_price"`     // in paise
	ImageURL      string `json:"image_url"`
	IsActive      *bool  `json:"is_active"`
}

// Page is a CMS content page (Terms, Privacy, Refund).
type Page struct {
	ID        int64     `json:"id"`
	Slug      string    `json:"slug"`
	Title     string    `json:"title"`
	Content   string    `json:"content"`
	UpdatedAt time.Time `json:"updated_at"`
}

// PageRequest is the payload for page create/update.
type PageRequest struct {
	Slug    string `json:"slug"`
	Title   string `json:"title"`
	Content string `json:"content"`
}