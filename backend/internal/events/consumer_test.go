package events

import (
	"testing"
	"time"

	"animeat/backend/internal/platform"
)

func TestNotificationForEvent(t *testing.T) {
	vendorID := "vendor-1"
	userID := "user-1"

	base := OrderEventPayload{
		OrderID:     "ORD-1",
		UserID:      userID,
		VendorID:    &vendorID,
		TotalAmount: platform.FromRupees(100),
		Timestamp:   time.Now().UTC(),
	}

	tests := []struct {
		name          string
		event         OrderEventPayload
		wantUserID    string
		wantTitle     string
		wantNil       bool
	}{
		{name: "created notifies vendor", event: withType(base, "orders.created"), wantUserID: vendorID, wantTitle: "New order received"},
		{name: "confirmed notifies vendor", event: withType(base, "orders.confirmed"), wantUserID: vendorID},
		{name: "paid notifies vendor", event: withType(base, "orders.paid"), wantUserID: vendorID},
		{name: "accepted notifies customer", event: withType(base, "orders.accepted"), wantUserID: userID, wantTitle: "Order update"},
		{name: "picked_up notifies customer", event: withType(base, "orders.picked_up"), wantUserID: userID},
		{name: "delivered notifies customer", event: withType(base, "orders.delivered"), wantUserID: userID},
		{name: "completed notifies customer", event: withType(base, "orders.completed"), wantUserID: userID},
		{name: "cancelled notifies vendor", event: withType(base, "orders.cancelled"), wantUserID: vendorID, wantTitle: "Order cancelled"},
		{name: "unknown event produces nothing", event: withType(base, "orders.unknown"), wantNil: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := notificationForEvent(&tt.event)
			if tt.wantNil {
				if got != nil {
					t.Fatalf("expected nil recipient, got %+v", got)
				}
				return
			}
			if got == nil {
				t.Fatal("expected recipient, got nil")
			}
			if got.UserID != tt.wantUserID {
				t.Fatalf("expected recipient %q, got %q", tt.wantUserID, got.UserID)
			}
			if tt.wantTitle != "" && got.Title != tt.wantTitle {
				t.Fatalf("expected title %q, got %q", tt.wantTitle, got.Title)
			}
		})
	}
}

func withType(e OrderEventPayload, eventType string) OrderEventPayload {
	e.EventType = eventType
	e.Status = eventType[len("orders."):]
	return e
}