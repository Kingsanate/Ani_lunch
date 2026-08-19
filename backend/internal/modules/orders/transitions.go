package orders

import (
	"context"
	"errors"
	"fmt"
	"time"

	"animeat/backend/internal/authz"
	"animeat/backend/internal/events"
	"animeat/backend/internal/platform"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// ResolveActor determines the application role of the authenticated user.
func (s *Service) ResolveActor(ctx context.Context, userID string) (authz.ActorKind, error) {
	if s.db == nil || s.db.Pool == nil {
		return "", platform.ErrInternal
	}
	return authz.ResolveActor(ctx, s.db.Pool, userID)
}

// TransitionRequest contains the target status for a transition.
type TransitionRequest struct {
	Status string `json:"status"`
}

// TransitionOrder validates and applies a role-authorized status change.
func (s *Service) TransitionOrder(ctx context.Context, userID, orderID, newStatus string) (*Order, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	actor, err := s.ResolveActor(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Load current order state for authorization + transition validation.
	var currentStatus string
	var vendorID *string
	var riderID *string
	err = s.db.Pool.QueryRow(ctx, `
		SELECT status, vendor_id, rider_id FROM orders WHERE id = $1
	`, orderID).Scan(&currentStatus, &vendorID, &riderID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch order state: %w", err)
	}

	// Authorization per role.
	switch actor {
	case authz.ActorVendor:
		if vendorID == nil || *vendorID != userID {
			return nil, fmt.Errorf("%w: order does not belong to this vendor", platform.ErrForbidden)
		}
	case authz.ActorRider:
		if riderID == nil || *riderID != userID {
			return nil, fmt.Errorf("%w: order is not assigned to this rider", platform.ErrForbidden)
		}
	case authz.ActorCustomer:
		if newStatus != string(StatusCancelled) {
			return nil, fmt.Errorf("%w: customers may only cancel orders", platform.ErrForbidden)
		}
	case authz.ActorAdmin:
		// Admin may perform any transition.
	default:
		return nil, fmt.Errorf("%w: unknown actor", platform.ErrForbidden)
	}

	// Enforce the strict state machine.
	if err := ValidateTransition(OrderStatus(currentStatus), OrderStatus(newStatus)); err != nil {
		return nil, fmt.Errorf("%w: %v", platform.ErrConflict, err)
	}

	// Guarded update so concurrent transitions can't double-apply.
	var updated bool
	err = s.db.Pool.QueryRow(ctx, `
		UPDATE orders
		SET status = $2, updated_at = NOW()
		WHERE id = $1 AND status = $3
		RETURNING TRUE
	`, orderID, newStatus, currentStatus).Scan(&updated)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("%w: order status changed concurrently", platform.ErrConflict)
		}
		return nil, fmt.Errorf("failed to update order status: %w", err)
	}

	if s.publisher != nil {
		now := time.Now().UTC()
		_ = s.publisher.PublishOrderEvent(ctx, fmt.Sprintf("orders.%s", newStatus), &events.OrderEventPayload{
			EventID:   uuid.New().String(),
			EventType: fmt.Sprintf("orders.%s", newStatus),
			OrderID:   orderID,
			Status:    newStatus,
			Timestamp: now,
		})
	}

	return s.GetOrder(ctx, orderID)
}

// GetOrderAuthorized loads an order if the requesting user is allowed to see it.
func (s *Service) GetOrderAuthorized(ctx context.Context, userID, orderID string) (*Order, error) {
	order, err := s.GetOrder(ctx, orderID)
	if err != nil {
		return nil, err
	}

	actor, err := s.ResolveActor(ctx, userID)
	if err != nil {
		return nil, err
	}

	switch actor {
	case authz.ActorAdmin:
		return order, nil
	case authz.ActorVendor:
		if order.VendorID != nil && *order.VendorID == userID {
			return order, nil
		}
	case authz.ActorRider:
		if order.RiderID != nil && *order.RiderID == userID {
			return order, nil
		}
	}

	if order.UserID == userID {
		return order, nil
	}

	return nil, fmt.Errorf("%w: user cannot access this order", platform.ErrForbidden)
}

// GetOrder loads a full order by ID (internal projection).
func (s *Service) GetOrder(ctx context.Context, orderID string) (*Order, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	o, err := scanOrder(s.db.Pool.QueryRow(ctx, `
		SELECT id, user_id, vendor_id, rider_id, order_type, status, subtotal_paise, delivery_fee_paise,
		       discount_paise, total_amount_paise, coupon_code, payment_method, payment_status,
		       delivery_street, delivery_city, delivery_zip, delivery_lat, delivery_lng,
		       special_notes, idempotency_key, created_at, updated_at, items
		FROM orders WHERE id = $1
	`, orderID))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch order: %w", err)
	}
	return o, nil
}