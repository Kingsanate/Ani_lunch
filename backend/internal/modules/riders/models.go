package riders

import (
	"time"

	"animeat/backend/internal/platform"
)

// Rider represents a delivery partner profile.
type Rider struct {
	ID             string    `json:"id"`
	Name           string    `json:"name"`
	Phone          string    `json:"phone"`
	Email          string    `json:"email"`
	IsOnline       bool      `json:"is_online"`
	Latitude       *float64  `json:"latitude,omitempty"`
	Longitude      *float64  `json:"longitude,omitempty"`
	IsApproved     bool      `json:"is_approved"`
	ApprovalStatus string    `json:"approval_status"` // pending | approved | rejected
	RejectionReason *string  `json:"rejection_reason,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// UpdateProfileRequest contains editable rider profile fields.
type UpdateProfileRequest struct {
	Name  *string `json:"name"`
	Phone *string `json:"phone"`
	Email *string `json:"email"`
}

// LocationUpdate contains rider GPS coordinates.
type LocationUpdate struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

// AvailabilityUpdate toggles rider online status.
type AvailabilityUpdate struct {
	IsOnline bool `json:"is_online"`
}

// RiderOrder is a lightweight order projection for rider workflows.
type RiderOrder struct {
	ID            string         `json:"id"`
	UserID        string         `json:"user_id"`
	VendorID      *string        `json:"vendor_id,omitempty"`
	Status        string         `json:"status"`
	Items         []OrderItem    `json:"items"`
	Subtotal      platform.Money `json:"subtotal"`
	DeliveryFee   platform.Money `json:"delivery_fee"`
	TotalAmount   platform.Money `json:"total_amount"`
	PaymentMethod string         `json:"payment_method"`
	PaymentStatus string         `json:"payment_status"`
	Address       string         `json:"address,omitempty"`
	Latitude      *float64       `json:"latitude,omitempty"`
	Longitude     *float64       `json:"longitude,omitempty"`
	SpecialNotes  string         `json:"special_notes,omitempty"`
	OrderTime     time.Time      `json:"order_time"`
	CustomerName  string         `json:"customer_name,omitempty"`
	CustomerPhone string         `json:"customer_phone,omitempty"`
}

// OrderItem is the minimal item projection used inside rider order views.
type OrderItem struct {
	ID        string         `json:"id"`
	ItemID    string         `json:"item_id"`
	Name      string         `json:"name"`
	Quantity  int            `json:"quantity"`
	UnitPrice platform.Money `json:"unit_price"`
	Subtotal  platform.Money `json:"subtotal"`
}