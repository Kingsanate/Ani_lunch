package orders

import (
	"time"

	"animeat/backend/internal/platform"
)

// Order represents an order in the database.
type Order struct {
	ID             string             `json:"id"`
	UserID         string             `json:"user_id"`
	VendorID       *string            `json:"vendor_id,omitempty"`
	RiderID        *string            `json:"rider_id,omitempty"`
	OrderType      string             `json:"order_type"`
	Status         OrderStatus        `json:"status"`
	Subtotal       platform.Money     `json:"subtotal"`
	DeliveryFee    platform.Money     `json:"delivery_fee"`
	Discount       platform.Money     `json:"discount"`
	TotalAmount    platform.Money     `json:"total_amount"`
	CouponCode     *string            `json:"coupon_code,omitempty"`
	PaymentMethod  string             `json:"payment_method"`
	PaymentStatus  string             `json:"payment_status"`
	DeliveryStreet string             `json:"delivery_street"`
	DeliveryCity   string             `json:"delivery_city"`
	DeliveryZip    string             `json:"delivery_zip"`
	DeliveryLat    *float64           `json:"delivery_lat,omitempty"`
	DeliveryLng    *float64           `json:"delivery_lng,omitempty"`
	SpecialNotes   *string            `json:"special_notes,omitempty"`
	IdempotencyKey *string            `json:"idempotency_key,omitempty"`
	CreatedAt      time.Time          `json:"created_at"`
	UpdatedAt      time.Time          `json:"updated_at"`
	Items          []OrderItemSummary `json:"items,omitempty"`
}

// OrderItemSummary represents item details within an order.
type OrderItemSummary struct {
	ID        string         `json:"id"`
	ItemID    string         `json:"item_id"`
	Name      string         `json:"name"`
	UnitPrice platform.Money `json:"unit_price"`
	Quantity  int            `json:"quantity"`
	Subtotal  platform.Money `json:"subtotal"`
	// Price is the unit price in integer rupees — kept for backward
	// compatibility with the legacy Flutter item snapshot contract
	// (orders_page/vendor read item['price']).
	Price int     `json:"price"`
	Image *string `json:"image,omitempty"`
}

// CreateOrderRequest represents client input for order placement.
type CreateOrderRequest struct {
	IdempotencyKey string             `json:"idempotency_key"`
	VendorID       *string            `json:"vendor_id"`
	OrderType      *string            `json:"order_type"` // 'meat' | 'lunch' (inferred when omitted)
	PaymentMethod  string             `json:"payment_method"`
	CouponCode     *string            `json:"coupon_code"`
	DeliveryStreet string             `json:"delivery_street"`
	DeliveryCity   string             `json:"delivery_city"`
	DeliveryZip    string             `json:"delivery_zip"`
	DeliveryLat    *float64           `json:"delivery_lat"`
	DeliveryLng    *float64           `json:"delivery_lng"`
	SpecialNotes   *string            `json:"special_notes"`
	Items          []OrderItemRequest `json:"items"`
}

// OrderItemRequest represents an item in the create order request.
type OrderItemRequest struct {
	ItemID   string            `json:"item_id"`
	Quantity int               `json:"quantity"`
	// Customizations carries the user's choices (e.g. {"Rice": "...", "Meat": "2x Chicken, 1x Mutton"})
	// so extra-piece charges can be priced server-side. Clients can never set prices.
	Customizations map[string]string `json:"customizations,omitempty"`
}
