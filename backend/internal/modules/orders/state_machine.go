package orders

import (
	"fmt"
)

type OrderStatus string

const (
	StatusPendingPayment OrderStatus = "pending_payment"
	StatusPending        OrderStatus = "pending"
	StatusConfirmed      OrderStatus = "confirmed"
	StatusPreparing      OrderStatus = "preparing"
	StatusReadyForPickup OrderStatus = "ready_for_pickup"
	StatusAccepted       OrderStatus = "accepted"
	StatusPickedUp       OrderStatus = "picked_up"
	StatusDelivered      OrderStatus = "delivered"
	StatusCancelled      OrderStatus = "cancelled"
)

// validTransitions maps each current status to the set of valid next statuses.
var validTransitions = map[OrderStatus]map[OrderStatus]bool{
	StatusPendingPayment: {
		StatusConfirmed: true,
		StatusPending:   true,
		StatusCancelled: true,
	},
	StatusPending: {
		StatusConfirmed: true,
		StatusPreparing: true,
		StatusCancelled: true,
	},
	StatusConfirmed: {
		StatusPreparing: true,
		StatusCancelled: true,
	},
	StatusPreparing: {
		StatusReadyForPickup: true,
		StatusCancelled:      true,
	},
	StatusReadyForPickup: {
		StatusAccepted:  true,
		StatusCancelled: true,
	},
	StatusAccepted: {
		StatusPickedUp:       true,
		StatusReadyForPickup: true, // If rider cancels/reassigns
		StatusCancelled:      true,
	},
	StatusPickedUp: {
		StatusDelivered: true,
		StatusCancelled: true,
	},
	StatusDelivered: {},
	StatusCancelled: {},
}

// CanTransition validates if moving from fromStatus to toStatus is permitted.
func CanTransition(from, to OrderStatus) bool {
	allowed, exists := validTransitions[from]
	if !exists {
		return false
	}
	return allowed[to]
}

// ValidateTransition returns an error if the status transition is invalid.
func ValidateTransition(from, to OrderStatus) error {
	if !CanTransition(from, to) {
		return fmt.Errorf("invalid order status transition from '%s' to '%s'", from, to)
	}
	return nil
}
