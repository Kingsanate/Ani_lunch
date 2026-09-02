package realtime

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"animeat/backend/internal/events"
	"github.com/nats-io/nats.go"
)

// Bridge is the shared NATS → Hub conduit. Exactly one subscription per
// subject family exists per process; events are routed in-process to the
// scoped channels, so fan-out costs zero extra NATS traffic and zero
// per-client database queries.
type Bridge struct {
	hub *Hub
	nc  *nats.Conn
}

// riderLocationEvent is the live GPS payload published by riders.
type riderLocationEvent struct {
	RiderID   string    `json:"rider_id"`
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Timestamp time.Time `json:"timestamp"`
}

// NewBridge wires the hub to NATS.
func NewBridge(hub *Hub, nc *nats.Conn) *Bridge {
	return &Bridge{hub: hub, nc: nc}
}

// Start registers the shared subscriptions. It blocks until ctx is cancelled.
func (b *Bridge) Start(ctx context.Context) {
	if b.nc == nil {
		slog.Warn("realtime bridge: NATS unavailable, skipping subscriptions")
		return
	}

	// Shared subscription for the whole order lifecycle subject family.
	if _, err := b.nc.Subscribe("orders.>", func(m *nats.Msg) {
		b.routeOrderEvent(m.Data)
	}); err != nil {
		slog.Error("realtime bridge: failed to subscribe to orders.>", "error", err)
	} else {
		slog.Info("realtime bridge: subscribed to orders.> (shared fan-out)")
	}

	// Live rider GPS — ephemeral, not JetStream-durable.
	if _, err := b.nc.Subscribe("riders.location", func(m *nats.Msg) {
		b.routeRiderLocation(m.Data)
	}); err != nil {
		slog.Error("realtime bridge: failed to subscribe to riders.location", "error", err)
	} else {
		slog.Info("realtime bridge: subscribed to riders.location")
	}

	<-ctx.Done()
}

// routeOrderEvent fans an order lifecycle event out to the scoped channels.
func (b *Bridge) routeOrderEvent(data []byte) {
	var ev events.OrderEventPayload
	if err := json.Unmarshal(data, &ev); err != nil {
		slog.Warn("realtime bridge: failed to decode order event", "error", err)
		return
	}

	// Customer tracking channel
	b.publish(ChannelOrder+":"+ev.OrderID, data)

	// Admin console channels
	b.publish(ChannelAdmin, data)
	b.publish("admin.orders", data)

	// Vendor app channels
	b.publish("vendor:orders", data)
	b.publish("vendor", data)
	if ev.VendorID != nil && *ev.VendorID != "" {
		b.publish(ChannelVendor+":"+*ev.VendorID, data)
	}

	// Rider app channels
	if ev.RiderID != nil && *ev.RiderID != "" {
		b.publish(ChannelRider+":"+*ev.RiderID, data)
	}

	// Broadcast ready_for_pickup to all online riders (unassigned only).
	if ev.Status == "ready_for_pickup" && (ev.RiderID == nil || *ev.RiderID == "") {
		b.publish(ChannelRiderBroadcast, data)
		b.publish("rider:available", data)
	}
}

// routeRiderLocation fans live GPS to the rider's scoped channel.
func (b *Bridge) routeRiderLocation(data []byte) {
	var loc riderLocationEvent
	if err := json.Unmarshal(data, &loc); err != nil {
		slog.Warn("realtime bridge: failed to decode rider location", "error", err)
		return
	}
	if loc.RiderID == "" {
		return
	}
	b.publish(ChannelRider+":"+loc.RiderID, data)
}

func (b *Bridge) publish(channel string, data []byte) {
	b.hub.Broadcast(channel, data)
}
