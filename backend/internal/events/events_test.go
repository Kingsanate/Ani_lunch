package events

import (
	"encoding/json"
	"testing"
	"time"

	"animeat/backend/internal/platform"
)

func TestOrderEventPayload_Serialization(t *testing.T) {
	vendorID := "vendor-uuid-777"
	event := OrderEventPayload{
		EventID:        "evt-001",
		EventType:      "orders.created",
		OrderID:        "ORD-2026-001",
		UserID:         "user-123",
		VendorID:       &vendorID,
		Status:         "pending",
		TotalAmount:    platform.FromRupees(350.50), // 35050 paise
		IdempotencyKey: "idem-abc-xyz",
		Timestamp:      time.Now().UTC(),
	}

	bytes, err := json.Marshal(event)
	if err != nil {
		t.Fatalf("failed to marshal event: %v", err)
	}

	var decoded OrderEventPayload
	if err := json.Unmarshal(bytes, &decoded); err != nil {
		t.Fatalf("failed to unmarshal event: %v", err)
	}

	if decoded.OrderID != "ORD-2026-001" {
		t.Errorf("OrderID = %s, expected ORD-2026-001", decoded.OrderID)
	}

	if decoded.TotalAmount != 35050 {
		t.Errorf("TotalAmount = %v, expected 35050 paise", decoded.TotalAmount)
	}

	if decoded.TotalAmount.String() != "₹350.50" {
		t.Errorf("TotalAmount.String() = %s, expected ₹350.50", decoded.TotalAmount.String())
	}
}
