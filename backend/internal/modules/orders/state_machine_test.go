package orders

import (
	"testing"
)

func TestOrderStateMachine(t *testing.T) {
	validSteps := []struct {
		from OrderStatus
		to   OrderStatus
	}{
		{StatusPendingPayment, StatusConfirmed},
		{StatusConfirmed, StatusPreparing},
		{StatusPreparing, StatusReadyForPickup},
		{StatusReadyForPickup, StatusAccepted},
		{StatusAccepted, StatusPickedUp},
		{StatusPickedUp, StatusDelivered},
		{StatusPreparing, StatusCancelled},
	}

	for _, step := range validSteps {
		if err := ValidateTransition(step.from, step.to); err != nil {
			t.Errorf("expected transition %s -> %s to be valid, got: %v", step.from, step.to, err)
		}
	}

	invalidSteps := []struct {
		from OrderStatus
		to   OrderStatus
	}{
		{StatusPending, StatusDelivered},
		{StatusDelivered, StatusPreparing},
		{StatusDelivered, StatusCancelled},
		{StatusCancelled, StatusConfirmed},
		{StatusReadyForPickup, StatusDelivered},
	}

	for _, step := range invalidSteps {
		if err := ValidateTransition(step.from, step.to); err == nil {
			t.Errorf("expected transition %s -> %s to be INVALID, but got nil error", step.from, step.to)
		}
	}
}
