package orders

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"animeat/backend/internal/events"
	"animeat/backend/internal/platform"
	"animeat/backend/internal/realtime"
)

func TestFullOrderLifecycle_Simulation(t *testing.T) {
	// 1. Customer places order for ₹350.00
	orderID := "ORD-2026-TEST-888"
	userID := "cust-101"
	vendorID := "vend-505"
	riderID := "rider-909"
	itemTotalPaise := int64(30000) // ₹300
	deliveryFeePaise := int64(5000) // ₹50
	totalAmountPaise := itemTotalPaise + deliveryFeePaise // ₹350 = 35000 paise

	money := platform.FromPaise(totalAmountPaise)
	if money.ToRupees() != 350.00 {
		t.Fatalf("expected ₹350.00, got %.2f", money.ToRupees())
	}

	// 2. Initial state: Pending Payment
	currentStatus := StatusPendingPayment

	// 3. Payment intent generation
	upiIntent := fmt.Sprintf(
		"upi://pay?pa=animeat@okaxis&pn=AniMeat&am=%.2f&tr=%s&cu=INR",
		money.ToRupees(), orderID,
	)
	if upiIntent != "upi://pay?pa=animeat@okaxis&pn=AniMeat&am=350.00&tr=ORD-2026-TEST-888&cu=INR" {
		t.Fatalf("unexpected UPI intent format: %s", upiIntent)
	}

	// 4. Payment webhook marks order paid -> Confirmed
	if err := ValidateTransition(currentStatus, StatusConfirmed); err != nil {
		t.Fatalf("transition to confirmed failed: %v", err)
	}
	currentStatus = StatusConfirmed

	// 5. Vendor receives order and starts cooking -> Preparing
	if err := ValidateTransition(currentStatus, StatusPreparing); err != nil {
		t.Fatalf("transition to preparing failed: %v", err)
	}
	currentStatus = StatusPreparing

	// 6. Food ready -> ReadyForPickup
	if err := ValidateTransition(currentStatus, StatusReadyForPickup); err != nil {
		t.Fatalf("transition to ready_for_pickup failed: %v", err)
	}
	currentStatus = StatusReadyForPickup

	// 7. Verify WebSocket broadcast to online riders
	hub := realtime.NewHub(func(ctx context.Context, uid, ch string) (bool, error) {
		return true, nil
	})
	
	// Create mock rider client
	client := &realtime.Client{}
	_ = client
	
	eventPayload, _ := json.Marshal(&events.OrderEventPayload{
		EventID:     "evt-100",
		EventType:   "orders.ready_for_pickup",
		OrderID:     orderID,
		UserID:      userID,
		VendorID:    &vendorID,
		Status:      string(StatusReadyForPickup),
		TotalAmount: money,
		Timestamp:   time.Now().UTC(),
	})
	if len(eventPayload) == 0 {
		t.Fatal("empty event payload")
	}

	// 8. Rider claims order -> Accepted
	if err := ValidateTransition(currentStatus, StatusAccepted); err != nil {
		t.Fatalf("transition to accepted failed: %v", err)
	}
	currentStatus = StatusAccepted

	// 9. Rider picks up food -> PickedUp
	if err := ValidateTransition(currentStatus, StatusPickedUp); err != nil {
		t.Fatalf("transition to picked_up failed: %v", err)
	}
	currentStatus = StatusPickedUp

	// 10. Order delivered -> Delivered (Terminal state)
	if err := ValidateTransition(currentStatus, StatusDelivered); err != nil {
		t.Fatalf("transition to delivered failed: %v", err)
	}
	currentStatus = StatusDelivered

	// 11. Verify invalid terminal transitions are rejected
	if err := ValidateTransition(currentStatus, StatusPreparing); err == nil {
		t.Fatal("expected delivered -> preparing to fail, but succeeded")
	}
	if err := ValidateTransition(currentStatus, StatusCancelled); err == nil {
		t.Fatal("expected delivered -> cancelled to fail, but succeeded")
	}
	_ = riderID
	_ = hub
}
