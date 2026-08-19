package events

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"animeat/backend/internal/observability"
	"animeat/backend/internal/platform"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

type EventPublisher struct {
	js jetstream.JetStream
	nc *nats.Conn
}

func NewEventPublisher(js jetstream.JetStream) *EventPublisher {
	return &EventPublisher{js: js}
}

// WithCoreConn attaches the raw NATS connection for ephemeral (non-durable)
// subjects that no JetStream stream covers.
func (p *EventPublisher) WithCoreConn(nc *nats.Conn) *EventPublisher {
	p.nc = nc
	return p
}

// OrderEventPayload represents standard event metadata and payload.
type OrderEventPayload struct {
	EventID        string         `json:"event_id"`
	EventType      string         `json:"event_type"` // e.g. "orders.created", "orders.paid"
	OrderID        string         `json:"order_id"`
	UserID         string         `json:"user_id"`
	VendorID       *string        `json:"vendor_id,omitempty"`
	RiderID        *string        `json:"rider_id,omitempty"`
	Status         string         `json:"status"`
	TotalAmount    platform.Money `json:"total_amount"`
	IdempotencyKey string         `json:"idempotency_key,omitempty"`
	Timestamp      time.Time      `json:"timestamp"`
}

// PublishOrderEvent publishes a durable order lifecycle event to NATS JetStream.
func (p *EventPublisher) PublishOrderEvent(ctx context.Context, subject string, event *OrderEventPayload) error {
	if p.js == nil {
		return nil // No-op if JetStream not connected in local dev
	}

	payload, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal order event: %w", err)
	}

	// Use event ID / idempotency key as Msg-Id for deduplication
	msgID := event.EventID
	if event.IdempotencyKey != "" {
		msgID = fmt.Sprintf("%s-%s", event.EventType, event.IdempotencyKey)
	}

	_, err = p.js.Publish(ctx, subject, payload, jetstream.WithMsgID(msgID))
	if err == nil {
		observability.RecordEventPublished(subject)
	}
	return err
}

// PublishRiderLocation broadcasts live GPS on the ephemeral
// "riders.location" subject (core NATS, no JetStream durability).
func (p *EventPublisher) PublishRiderLocation(ctx context.Context, riderID string, latitude, longitude float64) {
	if p.nc == nil {
		return
	}
	payload, err := json.Marshal(map[string]interface{}{
		"rider_id":   riderID,
		"latitude":   latitude,
		"longitude":  longitude,
		"timestamp":  time.Now().UTC(),
	})
	if err != nil {
		return
	}
	if err := p.nc.Publish("riders.location", payload); err == nil {
		observability.RecordEventPublished("riders.location")
	}
}
