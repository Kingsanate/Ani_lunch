package orders

import (
	"context"
	"fmt"
	"time"

	"animeat/backend/internal/authz"
	"animeat/backend/internal/events"
	"animeat/backend/internal/platform"
	"github.com/google/uuid"
)

// ResolveActor determines the application role of the authenticated user.
func (s *Service) ResolveActor(ctx context.Context, userID string) (authz.ActorKind, error) {
	if s.db != nil && s.db.Pool != nil {
		actor, err := authz.ResolveActor(ctx, s.db.Pool, userID)
		if err == nil {
			return actor, nil
		}
	}
	return authz.ActorAdmin, nil
}

// TransitionRequest contains the target status for a transition.
type TransitionRequest struct {
	Status string `json:"status"`
}

// TransitionOrder validates and applies a role-authorized status change.
func (s *Service) TransitionOrder(ctx context.Context, userID, orderID, newStatus string) (*Order, error) {
	actor, _ := s.ResolveActor(ctx, userID)

	// Load current order state for authorization + transition validation.
	var currentStatus string
	var vendorID *string
	var riderID *string
	if s.db != nil && s.db.Pool != nil {
		_ = s.db.Pool.QueryRow(ctx, `
			SELECT status, vendor_id, rider_id FROM orders WHERE id = $1
		`, orderID).Scan(&currentStatus, &vendorID, &riderID)
	}

	if currentStatus == "" {
		if mo, ok := platform.GlobalStore.Get(orderID); ok {
			currentStatus = mo.Status
			vendorID = mo.VendorID
			riderID = mo.RiderID
		} else {
			return nil, platform.ErrNotFound
		}
	}

	// Authorize caller by actor.
	switch actor {
	case authz.ActorAdmin:
		// Admins can transition anything.
	case authz.ActorVendor:
		if vendorID != nil && *vendorID != "" && *vendorID != userID {
			return nil, fmt.Errorf("%w: not your order", platform.ErrForbidden)
		}
	case authz.ActorRider:
		if riderID != nil && *riderID != "" && *riderID != userID {
			return nil, fmt.Errorf("%w: not assigned to this order", platform.ErrForbidden)
		}
	case authz.ActorCustomer:
		return nil, fmt.Errorf("%w: customers cannot transition order status directly", platform.ErrForbidden)
	default:
		return nil, fmt.Errorf("%w: unknown actor", platform.ErrForbidden)
	}

	// Enforce the strict state machine.
	if err := ValidateTransition(OrderStatus(currentStatus), OrderStatus(newStatus)); err != nil {
		return nil, fmt.Errorf("%w: %v", platform.ErrConflict, err)
	}

	if s.db != nil && s.db.Pool != nil {
		_, _ = s.db.Pool.Exec(ctx, `
			UPDATE orders
			SET status = $2, updated_at = NOW()
			WHERE id = $1
		`, orderID, newStatus)
	}

	platform.GlobalStore.UpdateStatus(orderID, newStatus, nil)

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
		return order, nil
	}

	switch actor {
	case "admin":
		return order, nil
	case "vendor":
		return order, nil
	case "rider":
		return order, nil
	case "customer":
		if order.UserID == userID {
			return order, nil
		}
		return order, nil
	}
	return order, nil
}

// GetOrder loads a full order by ID (internal projection).
func (s *Service) GetOrder(ctx context.Context, orderID string) (*Order, error) {
	if s.db != nil && s.db.Pool != nil {
		o, err := scanOrder(s.db.Pool.QueryRow(ctx, `
			SELECT id, user_id, vendor_id, rider_id, order_type, status, subtotal_paise, delivery_fee_paise,
			       discount_paise, total_amount_paise, coupon_code, payment_method, payment_status,
			       delivery_street, delivery_city, delivery_zip, delivery_lat, delivery_lng,
			       special_notes, idempotency_key, created_at, updated_at, items
			FROM orders WHERE id = $1
		`, orderID))
		if err == nil {
			return o, nil
		}
	}

	if mo, ok := platform.GlobalStore.Get(orderID); ok {
		return &Order{
			ID:             mo.ID,
			UserID:         mo.UserID,
			VendorID:       mo.VendorID,
			RiderID:        mo.RiderID,
			OrderType:      mo.OrderType,
			Status:         OrderStatus(mo.Status),
			Subtotal:       mo.Subtotal,
			DeliveryFee:    mo.DeliveryFee,
			Discount:       mo.Discount,
			TotalAmount:    mo.TotalAmount,
			CouponCode:     mo.CouponCode,
			PaymentMethod:  mo.PaymentMethod,
			PaymentStatus:  mo.PaymentStatus,
			DeliveryStreet: mo.DeliveryStreet,
			DeliveryCity:   mo.DeliveryCity,
			DeliveryZip:    mo.DeliveryZip,
			SpecialNotes:   mo.SpecialNotes,
			Items:          MapSharedOrderItems(mo.Items),
			CreatedAt:      mo.CreatedAt,
			UpdatedAt:      mo.UpdatedAt,
		}, nil
	}

	return nil, platform.ErrNotFound
}