package events

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"animeat/backend/internal/database"
	"github.com/nats-io/nats.go/jetstream"
)

// notificationRecipient carries the target user and message body for an event.
type notificationRecipient struct {
	UserID string
	Title  string
	Body   string
	Type   string
}

// notificationForEvent maps an order lifecycle event to a human notification.
// Pure function: deterministic, unit-testable, no I/O.
func notificationForEvent(event *OrderEventPayload) *notificationRecipient {
	switch event.EventType {
	case "orders.created", "orders.confirmed", "orders.paid":
		if event.VendorID != nil {
			return &notificationRecipient{
				UserID: *event.VendorID,
				Title:  "New order received",
				Body:   fmt.Sprintf("Order %s is awaiting your kitchen.", event.OrderID),
				Type:   "vendor_order",
			}
		}
	case "orders.accepted", "orders.picked_up", "orders.out_for_delivery", "orders.delivered", "orders.completed":
		return &notificationRecipient{
			UserID: event.UserID,
			Title:  "Order update",
			Body:   fmt.Sprintf("Order %s is now %s.", event.OrderID, event.Status),
			Type:   "order_update",
		}
	case "orders.cancelled":
		if event.VendorID != nil {
			return &notificationRecipient{
				UserID: *event.VendorID,
				Title:  "Order cancelled",
				Body:   fmt.Sprintf("Order %s was cancelled.", event.OrderID),
				Type:   "order_cancelled",
			}
		}
	}
	return nil
}

// PushSender delivers push notifications (e.g. FCM/APNs) to mobile devices.
type PushSender interface {
	SendToUser(ctx context.Context, userID, title, body string, data map[string]string) error
}

type EventConsumer struct {
	js     jetstream.JetStream
	db     *database.Postgres
	pusher PushSender
}

func NewEventConsumer(js jetstream.JetStream, db *database.Postgres) *EventConsumer {
	return &EventConsumer{js: js, db: db}
}

func (c *EventConsumer) WithPusher(pusher PushSender) *EventConsumer {
	c.pusher = pusher
	return c
}

// StartNotificationWorker consumes order lifecycle events and writes user
// notifications to PostgreSQL. Idempotent via the UNIQUE source_event_id.
func (c *EventConsumer) StartNotificationWorker(ctx context.Context) error {
	if c.js == nil {
		return nil
	}

	consumer, err := c.js.CreateOrUpdateConsumer(ctx, StreamOrders, jetstream.ConsumerConfig{
		Durable:       "notification-writer-group",
		Description:   "Persists order lifecycle events as user notifications",
		FilterSubject: "orders.*",
		AckPolicy:     jetstream.AckExplicitPolicy,
		MaxDeliver:    5,
		AckWait:       10 * time.Second,
	})
	if err != nil {
		return fmt.Errorf("failed to create notification consumer: %w", err)
	}

	go func() {
		iter, err := consumer.Messages()
		if err != nil {
			slog.Error("failed to open notification message iterator", "error", err)
			return
		}
		defer iter.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			default:
				msg, err := iter.Next()
				if err != nil {
					continue
				}

				var event OrderEventPayload
				if err := json.Unmarshal(msg.Data(), &event); err != nil {
					slog.Error("failed to unmarshal order event for notification", "error", err)
					_ = msg.Term()
					continue
				}

				if err := c.persistNotification(ctx, &event); err != nil {
					slog.Warn("notification persistence failed, will retry", "error", err, "order_id", event.OrderID)
					_ = msg.NakWithDelay(2 * time.Second)
					continue
				}

				_ = msg.Ack()
			}
		}
	}()

	return nil
}

// persistNotification inserts a notification row idempotently (ON CONFLICT DO NOTHING).
func (c *EventConsumer) persistNotification(ctx context.Context, event *OrderEventPayload) error {
	if c.db == nil || c.db.Pool == nil {
		return nil // Notifications are best-effort when DB is unavailable
	}

	recipient := notificationForEvent(event)
	if recipient == nil {
		return nil
	}

	_, err := c.db.Pool.Exec(ctx, `
		INSERT INTO notifications (user_id, title, body, notification_type, entity_type, entity_id, source_event_id, created_at)
		VALUES ($1, $2, $3, $4, 'order', $5, $6, $7)
		ON CONFLICT (source_event_id) DO NOTHING
	`, recipient.UserID, recipient.Title, recipient.Body, recipient.Type,
		event.OrderID, event.EventID, event.Timestamp)

	if err == nil && c.pusher != nil {
		_ = c.pusher.SendToUser(ctx, recipient.UserID, recipient.Title, recipient.Body, map[string]string{
			"order_id":          event.OrderID,
			"event_type":        event.EventType,
			"status":            event.Status,
			"notification_type": recipient.Type,
		})
	}
	return err
}

// StartKitchenDispatchWorker listens for new/paid orders to notify kitchen vendors.
func (c *EventConsumer) StartKitchenDispatchWorker(ctx context.Context) error {
	if c.js == nil {
		return nil
	}

	consumer, err := c.js.CreateOrUpdateConsumer(ctx, StreamOrders, jetstream.ConsumerConfig{
		Durable:       "kitchen-dispatch-group",
		Description:   "Delivers order creation and payment confirmation events to kitchen displays",
		FilterSubject: "orders.*",
		AckPolicy:     jetstream.AckExplicitPolicy,
		MaxDeliver:    5,
		AckWait:       10 * time.Second,
	})
	if err != nil {
		return fmt.Errorf("failed to create kitchen dispatch consumer: %w", err)
	}

	go func() {
		iter, err := consumer.Messages()
		if err != nil {
			slog.Error("failed to open consumer message iterator", "error", err)
			return
		}
		defer iter.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			default:
				msg, err := iter.Next()
				if err != nil {
					continue
				}

				var event OrderEventPayload
				if err := json.Unmarshal(msg.Data(), &event); err != nil {
					slog.Error("failed to unmarshal order event", "error", err)
					_ = msg.Term() // Poison message, terminate
					continue
				}

				slog.Info("kitchen_dispatch_received",
					"event_type", event.EventType,
					"order_id", event.OrderID,
					"vendor_id", event.VendorID,
					"amount", event.TotalAmount.String(),
				)

				// Acknowledge successful processing
				_ = msg.Ack()
			}
		}
	}()

	return nil
}

// StartRiderBroadcastWorker listens for orders marked ready for pickup to alert riders.
func (c *EventConsumer) StartRiderBroadcastWorker(ctx context.Context) error {
	if c.js == nil {
		return nil
	}

	consumer, err := c.js.CreateOrUpdateConsumer(ctx, StreamOrders, jetstream.ConsumerConfig{
		Durable:       "rider-broadcast-group",
		Description:   "Delivers ready_for_pickup events to notify nearby delivery partners",
		FilterSubject: "orders.ready_for_pickup",
		AckPolicy:     jetstream.AckExplicitPolicy,
		MaxDeliver:    5,
		AckWait:       10 * time.Second,
	})
	if err != nil {
		return fmt.Errorf("failed to create rider broadcast consumer: %w", err)
	}

	go func() {
		iter, err := consumer.Messages()
		if err != nil {
			slog.Error("failed to open rider broadcast message iterator", "error", err)
			return
		}
		defer iter.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			default:
				msg, err := iter.Next()
				if err != nil {
					continue
				}

				var event OrderEventPayload
				if err := json.Unmarshal(msg.Data(), &event); err != nil {
					_ = msg.Term()
					continue
				}

				slog.Info("rider_broadcast_dispatched",
					"order_id", event.OrderID,
					"status", event.Status,
				)

				_ = msg.Ack()
			}
		}
	}()

	return nil
}
