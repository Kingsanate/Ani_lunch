package realtime

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"animeat/backend/internal/events"
	"animeat/backend/internal/platform"
)

// fakeClient is a hub client whose outbound queue is directly readable.
// The websocket conn stays nil — pumps are never started in these tests.
type fakeClient struct {
	c *Client
}

func newFakeClient(hub *Hub, userID string) *fakeClient {
	f := &fakeClient{
		c: &Client{
			hub:      hub,
			userID:   userID,
			send:     make(chan []byte, sendBuffer),
			channels: make(map[string]struct{}),
			closed:   make(chan struct{}),
		},
	}
	hub.Register(f.c)
	return f
}

// next reads the next delivered event, or fails after a short timeout.
func (f *fakeClient) next(t *testing.T) []byte {
	t.Helper()
	select {
	case p := <-f.c.send:
		return p
	case <-time.After(500 * time.Millisecond):
		t.Fatal("no event delivered within timeout")
		return nil
	}
}

// assertNoEvent verifies nothing is delivered for the given window.
func (f *fakeClient) assertNoEvent(t *testing.T, d time.Duration) {
	t.Helper()
	select {
	case p := <-f.c.send:
		t.Fatalf("unexpected event delivered: %s", p)
	case <-time.After(d):
	}
}

func TestHubFanOutToScopedChannels(t *testing.T) {
	hub := NewHub(func(ctx context.Context, userID, channel string) (bool, error) {
		return userID == "u-1", nil
	})

	a := newFakeClient(hub, "u-1")
	b := newFakeClient(hub, "u-1")
	defer hub.Unregister(a.c)
	defer hub.Unregister(b.c)

	hub.Join(a.c, "order:ORD-1")
	hub.Join(b.c, "order:ORD-1")
	hub.Join(b.c, "rider:r-9")

	hub.Broadcast("order:ORD-1", []byte(`{"status":"preparing"}`))
	if got := a.next(t); string(got) != `{"status":"preparing"}` {
		t.Fatalf("client A got %q", got)
	}
	if got := b.next(t); string(got) != `{"status":"preparing"}` {
		t.Fatalf("client B got %q", got)
	}

	// Unjoined channel must not deliver.
	hub.Broadcast("order:ORD-2", []byte(`{"status":"paid"}`))
	a.assertNoEvent(t, 100*time.Millisecond)

	if hub.ClientCount() != 2 || hub.ChannelCount() != 2 {
		t.Fatalf("expected 2 clients and 2 channels, got %d/%d", hub.ClientCount(), hub.ChannelCount())
	}
}

func TestHubLeaveAndUnregister(t *testing.T) {
	hub := NewHub(nil)
	a := newFakeClient(hub, "u-1")
	defer hub.Unregister(a.c)

	hub.Join(a.c, "order:ORD-1")
	hub.Leave(a.c, "order:ORD-1")
	hub.Broadcast("order:ORD-1", []byte(`{"status":"x"}`))
	a.assertNoEvent(t, 100*time.Millisecond)

	hub.Unregister(a.c)
	if hub.ClientCount() != 0 || hub.ChannelCount() != 0 {
		t.Fatalf("expected empty hub, got %d clients %d channels", hub.ClientCount(), hub.ChannelCount())
	}
}

func TestAuthorizePolicyApplied(t *testing.T) {
	hub := NewHub(func(ctx context.Context, userID, channel string) (bool, error) {
		return userID == "u-1", nil
	})

	allowed, _ := hub.Authorize(context.Background(), "u-1", "order:ORD-1")
	if !allowed {
		t.Fatal("u-1 should be allowed")
	}
	allowed, _ = hub.Authorize(context.Background(), "u-2", "order:ORD-1")
	if allowed {
		t.Fatal("u-2 should be denied")
	}
}

func TestBridgeRoutesOrderEventToChannels(t *testing.T) {
	hub := NewHub(nil)
	a := newFakeClient(hub, "u-1")
	defer hub.Unregister(a.c)
	b := &Bridge{hub: hub}

	vendorID := "v-7"
	riderID := "r-9"
	ev, _ := json.Marshal(&events.OrderEventPayload{
		EventID:     "evt-1",
		EventType:   "orders.preparing",
		OrderID:     "ORD-1",
		UserID:      "u-1",
		VendorID:    &vendorID,
		RiderID:     &riderID,
		Status:      "preparing",
		TotalAmount: platform.FromRupees(100),
		Timestamp:   time.Now().UTC(),
	})

	hub.Join(a.c, "order:ORD-1")
	b.routeOrderEvent(ev)
	if got := a.next(t); string(got) != string(ev) {
		t.Fatalf("order channel payload mismatch: %s", got)
	}

	hub.Join(a.c, "rider:r-9")
	b.routeOrderEvent(ev)
	if got := a.next(t); string(got) != string(ev) {
		t.Fatalf("rider channel payload mismatch: %s", got)
	}

	hub.Join(a.c, "vendor:v-7")
	b.routeOrderEvent(ev)
	if got := a.next(t); string(got) != string(ev) {
		t.Fatalf("vendor channel payload mismatch: %s", got)
	}
}

func TestBridgeBroadcastsReadyForPickupUnassigned(t *testing.T) {
	hub := NewHub(nil)
	a := newFakeClient(hub, "u-1")
	defer hub.Unregister(a.c)
	b := &Bridge{hub: hub}

	ev, _ := json.Marshal(&events.OrderEventPayload{
		EventID:     "evt-2",
		EventType:   "orders.ready_for_pickup",
		OrderID:     "ORD-2",
		UserID:      "u-1",
		Status:      "ready_for_pickup",
		TotalAmount: platform.FromRupees(50),
		Timestamp:   time.Now().UTC(),
	})

	hub.Join(a.c, ChannelRiderBroadcast)
	b.routeOrderEvent(ev)
	if got := a.next(t); string(got) != string(ev) {
		t.Fatalf("broadcast payload mismatch: %s", got)
	}

	// Assigned orders must not broadcast.
	riderID := "r-1"
	assigned, _ := json.Marshal(&events.OrderEventPayload{
		EventID:     "evt-3",
		EventType:   "orders.ready_for_pickup",
		OrderID:     "ORD-3",
		UserID:      "u-1",
		RiderID:     &riderID,
		Status:      "ready_for_pickup",
		TotalAmount: platform.FromRupees(50),
		Timestamp:   time.Now().UTC(),
	})
	b.routeOrderEvent(assigned)
	a.assertNoEvent(t, 100*time.Millisecond)
}

func TestBridgeRoutesRiderLocation(t *testing.T) {
	hub := NewHub(nil)
	a := newFakeClient(hub, "u-1")
	defer hub.Unregister(a.c)
	b := &Bridge{hub: hub}

	loc, _ := json.Marshal(map[string]interface{}{
		"rider_id": "r-9", "latitude": 25.57, "longitude": 91.89,
	})

	hub.Join(a.c, "rider:r-9")
	b.routeRiderLocation(loc)
	if got := a.next(t); string(got) != string(loc) {
		t.Fatalf("location payload mismatch: %s", got)
	}
}

func TestParseChannel(t *testing.T) {
	cases := []struct {
		in       string
		kind     string
		id       string
		expected bool
	}{
		{"order:ORD-1", ChannelOrder, "ORD-1", true},
		{"rider:r-9", ChannelRider, "r-9", true},
		{"vendor:v-7", ChannelVendor, "v-7", true},
		{"riders.available", "", "", false},
		{"order:", "", "", false},
		{"", "", "", false},
		{"no-colon", "", "", false},
	}
	for _, tc := range cases {
		kind, id, ok := ParseChannel(tc.in)
		if ok != tc.expected || kind != tc.kind || id != tc.id {
			t.Fatalf("ParseChannel(%q) = (%q,%q,%v), want (%q,%q,%v)",
				tc.in, kind, id, ok, tc.kind, tc.id, tc.expected)
		}
	}
}