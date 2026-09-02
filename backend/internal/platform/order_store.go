package platform

import (
	"encoding/json"
	"sync"
	"time"
)

type SharedOrder struct {
	ID             string    `json:"id"`
	UserID         string    `json:"user_id"`
	VendorID       *string   `json:"vendor_id,omitempty"`
	RiderID        *string   `json:"rider_id,omitempty"`
	OrderType      string    `json:"order_type"`
	Status         string    `json:"status"`
	Subtotal       Money     `json:"subtotal_paise"`
	DeliveryFee    Money     `json:"delivery_fee_paise"`
	Discount       Money     `json:"discount_paise"`
	TotalAmount    Money     `json:"total_amount_paise"`
	CouponCode     *string   `json:"coupon_code,omitempty"`
	PaymentMethod  string    `json:"payment_method"`
	PaymentStatus  string    `json:"payment_status"`
	DeliveryStreet string    `json:"delivery_street"`
	DeliveryCity   string    `json:"delivery_city"`
	DeliveryZip    string    `json:"delivery_zip"`
	SpecialNotes   *string   `json:"special_notes,omitempty"`
	Items          []any     `json:"items"`
	CustomerName   string    `json:"customer_name"`
	OrderTime      time.Time `json:"order_time"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

type SharedDeal struct {
	ID             int64     `json:"id"`
	Title          string    `json:"title"`
	Description    string    `json:"description"`
	DiscountPct    float64   `json:"discount_percentage"`
	OriginalPrice  Money     `json:"original_price"`
	DealPrice      Money     `json:"deal_price"`
	BannerImageURL string    `json:"banner_image_url"`
	IsActive       bool      `json:"is_active"`
	CreatedAt      time.Time `json:"created_at"`
}

type OrderStore struct {
	mu     sync.RWMutex
	orders map[string]*SharedOrder
	deals  map[int64]*SharedDeal
	hub    Broadcaster
}

type Broadcaster interface {
	Broadcast(channel string, payload []byte)
}

var (
	vendorOne = "vendor-1"
	riderOne  = "rdr-1"
)

var GlobalStore = &OrderStore{
	orders: map[string]*SharedOrder{
		"ORD-HIST-101": {
			ID:             "ORD-HIST-101",
			UserID:         "usr-1",
			VendorID:       &vendorOne,
			RiderID:        &riderOne,
			OrderType:      "lunch",
			Status:         "delivered",
			Subtotal:       FromPaise(40000),
			DeliveryFee:    FromPaise(3000),
			TotalAmount:    FromPaise(43000),
			PaymentMethod:  "cod",
			PaymentStatus:  "paid",
			DeliveryStreet: "Laitumkhrah, Shillong",
			CustomerName:   "Valued Customer",
			OrderTime:      time.Now().Add(-2 * time.Hour),
			CreatedAt:      time.Now().Add(-2 * time.Hour),
			UpdatedAt:      time.Now().Add(-1 * time.Hour),
			Items: []any{
				map[string]any{
					"item_id":          "meal-4",
					"name":             "Khasi Thali",
					"quantity":         2,
					"unit_price_paise": 20000,
					"price":            200,
					"image":            "assets/images/beef.png",
				},
			},
		},
		"ORD-HIST-102": {
			ID:             "ORD-HIST-102",
			UserID:         "usr-1",
			VendorID:       &vendorOne,
			RiderID:        &riderOne,
			OrderType:      "lunch",
			Status:         "delivered",
			Subtotal:       FromPaise(20000),
			DeliveryFee:    FromPaise(3000),
			TotalAmount:    FromPaise(23000),
			PaymentMethod:  "online",
			PaymentStatus:  "paid",
			DeliveryStreet: "Police Bazaar, Shillong",
			CustomerName:   "Valued Customer",
			OrderTime:      time.Now().Add(-26 * time.Hour),
			CreatedAt:      time.Now().Add(-26 * time.Hour),
			UpdatedAt:      time.Now().Add(-25 * time.Hour),
			Items: []any{
				map[string]any{
					"item_id":          "meal-2",
					"name":             "Mizo Thali",
					"quantity":         1,
					"unit_price_paise": 20000,
					"price":            200,
					"image":            "assets/images/pork.png",
				},
			},
		},
	},
	deals: map[int64]*SharedDeal{
		1: {
			ID:             1,
			Title:          "Weekend Lunch Feast",
			Description:    "Flat 20% OFF on all lunch orders today",
			DiscountPct:    20.0,
			OriginalPrice:  FromPaise(25000),
			DealPrice:      FromPaise(20000),
			BannerImageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
			IsActive:       true,
			CreatedAt:      time.Now(),
		},
	},
}

func (s *OrderStore) SetHub(h Broadcaster) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.hub = h
}

func (s *OrderStore) Save(o *SharedOrder) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.orders[o.ID] = o

	if s.hub != nil {
		s.broadcastLocked(o)
	}
}

func (s *OrderStore) ListDeals() []*SharedDeal {
	s.mu.RLock()
	defer s.mu.RUnlock()
	list := make([]*SharedDeal, 0, len(s.deals))
	for _, d := range s.deals {
		list = append(list, d)
	}
	return list
}

func (s *OrderStore) SaveDeal(d *SharedDeal) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if d.ID == 0 {
		d.ID = time.Now().UnixMilli()
	}
	if d.CreatedAt.IsZero() {
		d.CreatedAt = time.Now().UTC()
	}
	s.deals[d.ID] = d
}

func (s *OrderStore) DeleteDeal(id int64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.deals, id)
}

func (s *OrderStore) broadcastLocked(o *SharedOrder) {
	event := map[string]any{
		"type": "order.updated",
		"data": map[string]any{
			"order_id":        o.ID,
			"user_id":         o.UserID,
			"vendor_id":       o.VendorID,
			"rider_id":        o.RiderID,
			"status":          o.Status,
			"total_amount":    o.TotalAmount,
			"subtotal":        o.Subtotal,
			"delivery_fee":    o.DeliveryFee,
			"delivery_street": o.DeliveryStreet,
			"customer_name":   o.CustomerName,
			"items":           o.Items,
			"timestamp":       time.Now().UTC().Format(time.RFC3339),
		},
	}
	bytes, _ := json.Marshal(event)

	s.hub.Broadcast("admin", bytes)
	s.hub.Broadcast("admin.orders", bytes)
	s.hub.Broadcast("vendor", bytes)
	s.hub.Broadcast("vendor:orders", bytes)
	if o.VendorID != nil && *o.VendorID != "" {
		s.hub.Broadcast("vendor:"+*o.VendorID, bytes)
	}
	s.hub.Broadcast("order:"+o.ID, bytes)
	if o.Status == "ready_for_pickup" {
		s.hub.Broadcast("riders.available", bytes)
		s.hub.Broadcast("rider:available", bytes)
	}
	if o.RiderID != nil && *o.RiderID != "" {
		s.hub.Broadcast("rider:"+*o.RiderID, bytes)
	}
}

func (s *OrderStore) Get(id string) (*SharedOrder, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	o, ok := s.orders[id]
	return o, ok
}

func (s *OrderStore) List() []*SharedOrder {
	s.mu.RLock()
	defer s.mu.RUnlock()
	list := make([]*SharedOrder, 0, len(s.orders))
	for _, o := range s.orders {
		list = append(list, o)
	}
	return list
}

func (s *OrderStore) UpdateStatus(id, status string, riderID *string) (*SharedOrder, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	o, ok := s.orders[id]
	if !ok {
		return nil, false
	}
	o.Status = status
	o.UpdatedAt = time.Now().UTC()
	if riderID != nil {
		o.RiderID = riderID
	}

	if s.hub != nil {
		s.broadcastLocked(o)
	}

	return o, true
}
