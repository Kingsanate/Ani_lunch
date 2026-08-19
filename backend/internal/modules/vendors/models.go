package vendors

import (
	"time"

	"animeat/backend/internal/platform"
)

// Vendor represents a restaurant / store partner.
type Vendor struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Address     string    `json:"address"`
	Phone       string    `json:"phone"`
	LocationLat *float64  `json:"location_lat,omitempty"`
	LocationLng *float64  `json:"location_lng,omitempty"`
	IsOpen      bool      `json:"is_open"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// UpdateVendorRequest contains editable vendor profile fields.
type UpdateVendorRequest struct {
	Name        *string  `json:"name"`
	Address     *string  `json:"address"`
	Phone       *string  `json:"phone"`
	LocationLat *float64 `json:"location_lat"`
	LocationLng *float64 `json:"location_lng"`
	IsOpen      *bool    `json:"is_open"`
}

// VendorOrder is the order projection used in vendor kitchen workflows.
type VendorOrder struct {
	ID            string         `json:"id"`
	UserID        string         `json:"user_id"`
	Status        string         `json:"status"`
	Items         []VendorItem   `json:"items"`
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

// VendorItem is the minimal item projection inside vendor order views.
type VendorItem struct {
	ID        string         `json:"id"`
	ItemID    string         `json:"item_id"`
	Name      string         `json:"name"`
	Quantity  int            `json:"quantity"`
	UnitPrice platform.Money `json:"unit_price"`
	Subtotal  platform.Money `json:"subtotal"`
}

// VendorStats summarizes a vendor's daily performance.
type VendorStats struct {
	OrdersToday   int            `json:"orders_today"`
	RevenueToday  platform.Money `json:"revenue_today"`
	PendingCount  int            `json:"pending_count"`
	PreparingCount int           `json:"preparing_count"`
	ReadyCount    int            `json:"ready_count"`
	CompletedToday int           `json:"completed_today"`
}