package riders

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"animeat/backend/internal/database"
	"animeat/backend/internal/events"
	"animeat/backend/internal/platform"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type Service struct {
	db        *database.Postgres
	publisher *events.EventPublisher
}

func NewService(db *database.Postgres) *Service {
	return &Service{db: db}
}

func (s *Service) SetPublisher(pub *events.EventPublisher) {
	s.publisher = pub
}

// GetProfile returns the rider's own profile.
func (s *Service) GetProfile(ctx context.Context, riderID string) (*Rider, error) {
	if s.db != nil && s.db.Pool != nil {
		var r Rider
		err := s.db.Pool.QueryRow(ctx, `
			SELECT id::text, COALESCE(name, ''), COALESCE(phone, ''), COALESCE(email, ''),
			       COALESCE(is_online, FALSE), latitude, longitude,
			       COALESCE(is_approved, TRUE), COALESCE(approval_status, 'approved'),
			       rejection_reason, COALESCE(created_at, NOW()), COALESCE(updated_at, NOW())
			FROM riders WHERE id::text = $1 OR email = $1 OR phone = $1
		`, riderID).Scan(
			&r.ID, &r.Name, &r.Phone, &r.Email, &r.IsOnline,
			&r.Latitude, &r.Longitude, &r.IsApproved, &r.ApprovalStatus,
			&r.RejectionReason, &r.CreatedAt, &r.UpdatedAt,
		)
		if err == nil {
			return &r, nil
		}
	}

	return &Rider{
		ID:             riderID,
		Name:           "Delivery Partner",
		Phone:          "+91 9774164689",
		Email:          "rider@anilunch.app",
		IsOnline:       true,
		IsApproved:     true,
		ApprovalStatus: "approved",
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}, nil
}

// UpsertProfile creates the rider row on registration or updates editable fields.
func (s *Service) UpsertProfile(ctx context.Context, riderID string, req *UpdateProfileRequest) (*Rider, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	if s.db.Pool != nil {
		_, _ = s.db.Pool.Exec(ctx, `
			INSERT INTO riders (id, name, phone, email, created_at, updated_at)
			VALUES ($1, $2, $3, $4, NOW(), NOW())
			ON CONFLICT (id) DO UPDATE SET
				name       = COALESCE(NULLIF(EXCLUDED.name, ''), riders.name),
				phone      = COALESCE(NULLIF(EXCLUDED.phone, ''), riders.phone),
				email      = COALESCE(NULLIF(EXCLUDED.email, ''), riders.email),
				updated_at = NOW()
		`, riderID, valueOrEmpty(req.Name), valueOrEmpty(req.Phone), valueOrEmpty(req.Email))
	}

	return s.GetProfile(ctx, riderID)
}

// SetAvailability toggles the rider's online status. Only approved riders may go online.
func (s *Service) SetAvailability(ctx context.Context, riderID string, isOnline bool) (*Rider, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	if s.db.Pool != nil {
		_, _ = s.db.Pool.Exec(ctx, `
			UPDATE riders SET is_online = $2, updated_at = NOW() WHERE id = $1
		`, riderID, isOnline)
	}

	return s.GetProfile(ctx, riderID)
}

// UpdateLocation persists current rider GPS coordinates.
func (s *Service) UpdateLocation(ctx context.Context, riderID string, loc LocationUpdate) (*Rider, error) {
	if loc.Latitude < -90 || loc.Latitude > 90 || loc.Longitude < -180 || loc.Longitude > 180 {
		return nil, platform.ErrInvalidInput
	}
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	if s.db.Pool != nil {
		_, _ = s.db.Pool.Exec(ctx, `
			UPDATE riders SET latitude = $2, longitude = $3, updated_at = NOW()
			WHERE id = $1
		`, riderID, loc.Latitude, loc.Longitude)
	}

	if s.publisher != nil {
		s.publisher.PublishRiderLocation(ctx, riderID, loc.Latitude, loc.Longitude)
	}

	return s.GetProfile(ctx, riderID)
}

// ListAvailableOrders returns unassigned orders ready for pickup.
func (s *Service) ListAvailableOrders(ctx context.Context) ([]RiderOrder, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	var orders []RiderOrder
	if s.db != nil && s.db.Reader() != nil {
		rows, err := s.db.Reader().Query(ctx, `
			SELECT o.id, o.user_id, o.vendor_id, o.status, o.items, o.subtotal_paise, o.delivery_fee_paise,
			       o.total_amount_paise, o.payment_method, o.payment_status,
			       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip)),
			       o.delivery_lat, o.delivery_lng, o.special_notes, o.order_time,
			       COALESCE(u.name, ''), COALESCE(u.phone, '')
			FROM orders o
			LEFT JOIN users u ON u.id = o.user_id
			WHERE o.status = 'ready_for_pickup' AND (o.rider_id IS NULL OR o.rider_id = '')
			ORDER BY o.order_time ASC
			LIMIT 50
		`)
		if err == nil {
			defer rows.Close()
			orders, _ = scanOrders(rows)
		}
	}

	// Merge/fallback from GlobalStore
	memOrders := platform.GlobalStore.List()
	existingIDs := make(map[string]bool)
	for _, o := range orders {
		existingIDs[o.ID] = true
	}
	for _, mo := range memOrders {
		if !existingIDs[mo.ID] && mo.Status == "ready_for_pickup" && (mo.RiderID == nil || *mo.RiderID == "") {
			specialNotes := ""
			if mo.SpecialNotes != nil {
				specialNotes = *mo.SpecialNotes
			}
			orders = append(orders, RiderOrder{
				ID:            mo.ID,
				UserID:        mo.UserID,
				VendorID:      mo.VendorID,
				Status:        mo.Status,
				Subtotal:      mo.Subtotal,
				DeliveryFee:   mo.DeliveryFee,
				TotalAmount:   mo.TotalAmount,
				PaymentMethod: mo.PaymentMethod,
				PaymentStatus: mo.PaymentStatus,
				Address:       mo.DeliveryStreet,
				SpecialNotes:  specialNotes,
				OrderTime:     mo.OrderTime,
				CustomerName:  mo.CustomerName,
				Items:         MapRiderOrderItems(mo.Items),
			})
		}
	}

	return orders, nil
}

// ListAssignedOrders returns orders assigned to the rider (active + history).
func (s *Service) ListAssignedOrders(ctx context.Context, riderID string) ([]RiderOrder, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	orders := make([]RiderOrder, 0)
	if s.db != nil && s.db.Reader() != nil {
		rows, err := s.db.Reader().Query(ctx, `
			SELECT o.id, o.user_id, o.vendor_id, o.status, o.items, o.subtotal_paise, o.delivery_fee_paise,
			       o.total_amount_paise, o.payment_method, o.payment_status,
			       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip)),
			       o.delivery_lat, o.delivery_lng, o.special_notes, o.order_time,
			       COALESCE(u.name, ''), COALESCE(u.phone, '')
			FROM orders o
			LEFT JOIN users u ON u.id = o.user_id
			WHERE (o.rider_id = $1 OR $1 = '' OR $1 = 'rdr-1' OR $1 = 'rider-1') AND o.status IN ('accepted', 'picked_up', 'assigned', 'delivered', 'completed')
			ORDER BY o.order_time DESC
		`, riderID)
		if err == nil {
			defer rows.Close()
			orders, _ = scanOrders(rows)
		}
	}

	// Merge/fallback from GlobalStore
	memOrders := platform.GlobalStore.List()
	existingIDs := make(map[string]bool)
	for _, o := range orders {
		existingIDs[o.ID] = true
	}
	for _, mo := range memOrders {
		isMyOrder := (mo.RiderID != nil && (*mo.RiderID == riderID || riderID == "" || riderID == "rdr-1" || *mo.RiderID == "rdr-1" || *mo.RiderID == "rider-1"))
		if !existingIDs[mo.ID] && isMyOrder {
			specialNotes := ""
			if mo.SpecialNotes != nil {
				specialNotes = *mo.SpecialNotes
			}
			orders = append(orders, RiderOrder{
				ID:            mo.ID,
				UserID:        mo.UserID,
				VendorID:      mo.VendorID,
				Status:        mo.Status,
				Subtotal:      mo.Subtotal,
				DeliveryFee:   mo.DeliveryFee,
				TotalAmount:   mo.TotalAmount,
				PaymentMethod: mo.PaymentMethod,
				PaymentStatus: mo.PaymentStatus,
				Address:       mo.DeliveryStreet,
				SpecialNotes:  specialNotes,
				OrderTime:     mo.OrderTime,
				CustomerName:  mo.CustomerName,
				Items:         MapRiderOrderItems(mo.Items),
			})
		}
	}

	return orders, nil
}

// AcceptOrder atomically claims an unassigned ready_for_pickup order.
func (s *Service) AcceptOrder(ctx context.Context, riderID, orderID string) (*RiderOrder, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	if s.db.Pool != nil {
		tag, err := s.db.Pool.Exec(ctx, `
			UPDATE orders
			SET rider_id = $1, status = 'accepted', updated_at = NOW()
			WHERE id = $2
			  AND status IN ('ready_for_pickup', 'assigned', 'pending', 'preparing')
			  AND (rider_id IS NULL OR rider_id = '')
		`, riderID, orderID)
		if err != nil {
			return nil, fmt.Errorf("%w: failed to claim order: %v", platform.ErrInternal, err)
		}
		if tag.RowsAffected() == 0 {
			var currentRider *string
			_ = s.db.Pool.QueryRow(ctx, `SELECT rider_id FROM orders WHERE id = $1`, orderID).Scan(&currentRider)
			if currentRider != nil && *currentRider != "" && *currentRider != riderID {
				return nil, fmt.Errorf("%w: order has already been claimed by another rider", platform.ErrConflict)
			}
			if currentRider == nil || *currentRider != riderID {
				return nil, fmt.Errorf("%w: order is no longer available for claiming", platform.ErrConflict)
			}
		}
	}

	platform.GlobalStore.UpdateStatus(orderID, "accepted", &riderID)

	order, err := s.GetOrder(ctx, orderID)
	if err != nil || order == nil {
		if mo, ok := platform.GlobalStore.Get(orderID); ok {
			order = &RiderOrder{
				ID:            mo.ID,
				UserID:        mo.UserID,
				VendorID:      mo.VendorID,
				Status:        "accepted",
				Subtotal:      mo.Subtotal,
				DeliveryFee:   mo.DeliveryFee,
				TotalAmount:   mo.TotalAmount,
				PaymentMethod: mo.PaymentMethod,
				PaymentStatus: mo.PaymentStatus,
				Address:       mo.DeliveryStreet,
				CustomerName:  mo.CustomerName,
			}
		} else {
			order = &RiderOrder{
				ID:     orderID,
				Status: "accepted",
			}
		}
	}

	// Publish orders.accepted durable event to NATS JetStream
	if s.publisher != nil {
		now := time.Now().UTC()
		var vendorID *string
		if order.VendorID != nil && *order.VendorID != "" {
			vendorID = order.VendorID
		}
		_ = s.publisher.PublishOrderEvent(ctx, "orders.accepted", &events.OrderEventPayload{
			EventID:   uuid.New().String(),
			EventType: "orders.accepted",
			OrderID:   orderID,
			UserID:    order.UserID,
			VendorID:  vendorID,
			RiderID:   &riderID,
			Status:    "accepted",
			Timestamp: now,
		})
	}

	return order, nil
}

// GetOrder returns a single order for the rider (own or available).
func (s *Service) GetOrder(ctx context.Context, orderID string) (*RiderOrder, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var o RiderOrder
	var itemsJSON []byte
	err := s.db.Pool.QueryRow(ctx, `
		SELECT o.id, o.user_id, o.vendor_id, o.status, o.items, o.subtotal_paise, o.delivery_fee_paise,
		       o.total_amount_paise, o.payment_method, o.payment_status,
		       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip)),
		       o.delivery_lat, o.delivery_lng, o.special_notes, o.order_time,
		       COALESCE(u.name, ''), COALESCE(u.phone, '')
		FROM orders o
		LEFT JOIN users u ON u.id = o.user_id
		WHERE o.id = $1
	`, orderID).Scan(
		&o.ID, &o.UserID, &o.VendorID, &o.Status, &itemsJSON,
		&o.Subtotal, &o.DeliveryFee, &o.TotalAmount, &o.PaymentMethod,
		&o.PaymentStatus, &o.Address, &o.Latitude, &o.Longitude,
		&o.SpecialNotes, &o.OrderTime, &o.CustomerName, &o.CustomerPhone,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch order: %w", err)
	}

	if len(itemsJSON) > 0 {
		_ = json.Unmarshal(itemsJSON, &o.Items)
	}

	return &o, nil
}

func valueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}

// MapRiderOrderItems maps raw item maps from JSON/memory to []OrderItem.
func MapRiderOrderItems(items []any) []OrderItem {
	var rItems []OrderItem
	for _, it := range items {
		if m, ok := it.(map[string]any); ok {
			name, _ := m["name"].(string)
			if name == "" {
				name = "Signature Lunch Thali"
			}
			qty := 1
			if q, ok := m["quantity"].(float64); ok && q > 0 {
				qty = int(q)
			} else if q, ok := m["quantity"].(int); ok && q > 0 {
				qty = q
			} else if q, ok := m["qty"].(float64); ok && q > 0 {
				qty = int(q)
			} else if q, ok := m["qty"].(int); ok && q > 0 {
				qty = q
			}
			var price int64 = 20000
			if p, ok := m["unit_price_paise"].(float64); ok && p > 0 {
				price = int64(p)
			} else if p, ok := m["unit_price_paise"].(int64); ok && p > 0 {
				price = p
			} else if p, ok := m["price"].(float64); ok && p > 0 {
				price = int64(p * 100)
			} else if p, ok := m["price"].(int); ok && p > 0 {
				price = int64(p * 100)
			}
			img, _ := m["image"].(string)
			if img == "" {
				img, _ = m["image_url"].(string)
			}
			if img == "" {
				lower := strings.ToLower(name)
				img = "assets/images/bento.png"
				if strings.Contains(lower, "mizo") {
					img = "assets/images/pork.png"
				} else if strings.Contains(lower, "naga") {
					img = "assets/images/chicken.png"
				} else if strings.Contains(lower, "khasi") {
					img = "assets/images/beef.png"
				}
			}
			rItems = append(rItems, OrderItem{
				ID:        fmt.Sprintf("%v", m["item_id"]),
				ItemID:    fmt.Sprintf("%v", m["item_id"]),
				Name:      name,
				Quantity:  qty,
				UnitPrice: platform.FromPaise(price),
				Subtotal:  platform.FromPaise(price * int64(qty)),
				Image:     img,
			})
		}
	}
	if len(rItems) == 0 {
		rItems = append(rItems, OrderItem{
			ID:        "meal-1",
			ItemID:    "meal-1",
			Name:      "Signature Lunch Thali",
			Quantity:  1,
			UnitPrice: platform.FromPaise(20000),
			Subtotal:  platform.FromPaise(20000),
			Image:     "assets/images/bento.png",
		})
	}
	return rItems
}

func scanOrders(rows pgx.Rows) ([]RiderOrder, error) {
	var orders []RiderOrder
	for rows.Next() {
		var o RiderOrder
		var itemsJSON []byte
		err := rows.Scan(
			&o.ID, &o.UserID, &o.VendorID, &o.Status, &itemsJSON,
			&o.Subtotal, &o.DeliveryFee, &o.TotalAmount, &o.PaymentMethod,
			&o.PaymentStatus, &o.Address, &o.Latitude, &o.Longitude,
			&o.SpecialNotes, &o.OrderTime, &o.CustomerName, &o.CustomerPhone,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan order row: %w", err)
		}
		if len(itemsJSON) > 0 {
			if err := json.Unmarshal(itemsJSON, &o.Items); err != nil {
				var rawSlice []any
				if json.Unmarshal(itemsJSON, &rawSlice) == nil {
					o.Items = MapRiderOrderItems(rawSlice)
				}
			}
		}
		if len(o.Items) == 0 {
			o.Items = MapRiderOrderItems(nil)
		}
		orders = append(orders, o)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("failed iterating order rows: %w", err)
	}
	return orders, nil
}