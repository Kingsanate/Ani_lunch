package riders

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
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
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var r Rider
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id, name, phone, email, is_online, latitude, longitude,
		       is_approved, approval_status, rejection_reason, created_at, updated_at
		FROM riders WHERE id = $1
	`, riderID).Scan(
		&r.ID, &r.Name, &r.Phone, &r.Email, &r.IsOnline,
		&r.Latitude, &r.Longitude, &r.IsApproved, &r.ApprovalStatus,
		&r.RejectionReason, &r.CreatedAt, &r.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch rider profile: %w", err)
	}

	return &r, nil
}

// UpsertProfile creates the rider row on registration or updates editable fields.
func (s *Service) UpsertProfile(ctx context.Context, riderID string, req *UpdateProfileRequest) (*Rider, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	_, err := s.db.Pool.Exec(ctx, `
		INSERT INTO riders (id, name, phone, email, created_at, updated_at)
		VALUES ($1, $2, $3, $4, NOW(), NOW())
		ON CONFLICT (id) DO UPDATE SET
			name       = COALESCE(NULLIF(EXCLUDED.name, ''), riders.name),
			phone      = COALESCE(NULLIF(EXCLUDED.phone, ''), riders.phone),
			email      = COALESCE(NULLIF(EXCLUDED.email, ''), riders.email),
			updated_at = NOW()
	`, riderID, valueOrEmpty(req.Name), valueOrEmpty(req.Phone), valueOrEmpty(req.Email))
	if err != nil {
		return nil, fmt.Errorf("failed to upsert rider profile: %w", err)
	}

	return s.GetProfile(ctx, riderID)
}

// SetAvailability toggles the rider's online status. Only approved riders may go online.
func (s *Service) SetAvailability(ctx context.Context, riderID string, isOnline bool) (*Rider, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	if isOnline {
		var approved bool
		err := s.db.Pool.QueryRow(ctx, `SELECT is_approved FROM riders WHERE id = $1`, riderID).Scan(&approved)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, platform.ErrNotFound
			}
			return nil, fmt.Errorf("failed to check rider approval: %w", err)
		}
		if !approved {
			return nil, fmt.Errorf("%w: rider is not approved yet", platform.ErrForbidden)
		}
	}

	_, err := s.db.Pool.Exec(ctx, `
		UPDATE riders SET is_online = $2, updated_at = NOW() WHERE id = $1
	`, riderID, isOnline)
	if err != nil {
		return nil, fmt.Errorf("failed to update rider availability: %w", err)
	}

	return s.GetProfile(ctx, riderID)
}

// UpdateLocation persists rider GPS coordinates. Only online riders update
// location, keeping stale writes away from the orders hot path.
func (s *Service) UpdateLocation(ctx context.Context, riderID string, loc LocationUpdate) (*Rider, error) {
	if loc.Latitude < -90 || loc.Latitude > 90 || loc.Longitude < -180 || loc.Longitude > 180 {
		return nil, fmt.Errorf("%w: invalid coordinates", platform.ErrInvalidInput)
	}

	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	_, err := s.db.Pool.Exec(ctx, `
		UPDATE riders SET latitude = $2, longitude = $3, updated_at = NOW()
		WHERE id = $1
	`, riderID, loc.Latitude, loc.Longitude)
	if err != nil {
		return nil, fmt.Errorf("failed to update rider location: %w", err)
	}

	// Live GPS fan-out: subscribers of the rider:{id} channel receive the
	// position without polling the database.
	if s.publisher != nil {
		s.publisher.PublishRiderLocation(ctx, riderID, loc.Latitude, loc.Longitude)
	}

	return s.GetProfile(ctx, riderID)
}

// ListAvailableOrders returns unassigned orders ready for pickup.
// Read-only and stale-tolerant: served from the read replica when configured.
// AcceptOrder re-validates state on the primary with a guarded UPDATE, so a
// stale listing can never cause double-assignment.
func (s *Service) ListAvailableOrders(ctx context.Context) ([]RiderOrder, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Reader().Query(ctx, `
		SELECT o.id, o.user_id, o.vendor_id, o.status, o.items, o.subtotal_paise, o.delivery_fee_paise,
		       o.total_amount_paise, o.payment_method, o.payment_status,
		       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip)),
		       o.delivery_lat, o.delivery_lng, o.special_notes, o.order_time,
		       COALESCE(u.name, ''), COALESCE(u.phone_number, '')
		FROM orders o
		LEFT JOIN users u ON u.id = o.user_id
		WHERE o.status = 'ready_for_pickup' AND (o.rider_id IS NULL OR o.rider_id = '')
		ORDER BY o.order_time ASC
		LIMIT 50
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to query available orders: %w", err)
	}
	defer rows.Close()

	return scanOrders(rows)
}

// ListAssignedOrders returns orders assigned to the rider.
// Read-only and stale-tolerant: served from the read replica when configured.
func (s *Service) ListAssignedOrders(ctx context.Context, riderID string) ([]RiderOrder, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Reader().Query(ctx, `
		SELECT o.id, o.user_id, o.vendor_id, o.status, o.items, o.subtotal_paise, o.delivery_fee_paise,
		       o.total_amount_paise, o.payment_method, o.payment_status,
		       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip)),
		       o.delivery_lat, o.delivery_lng, o.special_notes, o.order_time,
		       COALESCE(u.name, ''), COALESCE(u.phone_number, '')
		FROM orders o
		LEFT JOIN users u ON u.id = o.user_id
		WHERE o.rider_id = $1 AND o.status IN ('accepted', 'picked_up', 'assigned')
		ORDER BY o.order_time ASC
	`, riderID)
	if err != nil {
		return nil, fmt.Errorf("failed to query assigned orders: %w", err)
	}
	defer rows.Close()

	return scanOrders(rows)
}

// AcceptOrder atomically claims an unassigned ready_for_pickup order.
// Mirrors the legacy accept_order RPC with FOR UPDATE locking.
func (s *Service) AcceptOrder(ctx context.Context, riderID, orderID string) (*RiderOrder, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	tx, err := s.db.Pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	var updated bool
	err = tx.QueryRow(ctx, `
		UPDATE orders
		SET rider_id = $1, status = 'accepted', updated_at = NOW()
		WHERE id = $2
		  AND status IN ('ready_for_pickup', 'assigned')
		  AND (rider_id IS NULL OR rider_id = '')
		RETURNING TRUE
	`, riderID, orderID).Scan(&updated)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("%w: order is not available for acceptance", platform.ErrConflict)
		}
		return nil, fmt.Errorf("failed to accept order: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("failed to commit acceptance: %w", err)
	}

	if s.publisher != nil {
		now := time.Now().UTC()
		_ = s.publisher.PublishOrderEvent(ctx, "orders.accepted", &events.OrderEventPayload{
			EventID:   uuid.New().String(),
			EventType: "orders.accepted",
			OrderID:   orderID,
			RiderID:   &riderID,
			Status:    "accepted",
			Timestamp: now,
		})
	}

	order, err := s.GetOrder(ctx, orderID)
	if err != nil {
		return nil, err
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
		       COALESCE(u.name, ''), COALESCE(u.phone_number, '')
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
			_ = json.Unmarshal(itemsJSON, &o.Items)
		}
		orders = append(orders, o)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("failed iterating order rows: %w", err)
	}
	return orders, nil
}