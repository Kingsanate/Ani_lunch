package events

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

type NATSClient struct {
	Conn *nats.Conn
	JS   jetstream.JetStream
}

const (
	StreamOrders = "ORDERS"
)

// NewNATSClient connects to NATS and ensures the durable ORDERS JetStream stream exists.
func NewNATSClient(ctx context.Context, natsURL string) (*NATSClient, error) {
	nc, err := nats.Connect(
		natsURL,
		nats.Name("animeat-api"),
		nats.MaxReconnects(10),
		nats.ReconnectWait(2*time.Second),
		nats.DisconnectErrHandler(func(c *nats.Conn, err error) {
			slog.Warn("NATS disconnected", "error", err)
		}),
		nats.ReconnectHandler(func(c *nats.Conn) {
			slog.Info("NATS reconnected", "url", c.ConnectedUrl())
		}),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to NATS: %w", err)
	}

	js, err := jetstream.New(nc)
	if err != nil {
		nc.Close()
		return nil, fmt.Errorf("failed to initialize JetStream context: %w", err)
	}

	client := &NATSClient{
		Conn: nc,
		JS:   js,
	}

	// Create or update durable ORDERS stream with file storage & message deduplication
	streamCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()

	_, err = js.CreateOrUpdateStream(streamCtx, jetstream.StreamConfig{
		Name:        StreamOrders,
		Description: "Durable event log for all platform order lifecycle transitions",
		Subjects:    []string{"orders.*"},
		Retention:   jetstream.LimitsPolicy,
		Storage:     jetstream.FileStorage,
		MaxAge:      72 * time.Hour,
		Duplicates:  5 * time.Minute, // Deduplication window for idempotency
	})
	if err != nil {
		slog.Warn("could not configure JetStream stream on startup (server will operate in direct mode)", "error", err)
	} else {
		slog.Info("NATS JetStream ORDERS stream initialized successfully")
	}

	return client, nil
}

// Close terminates the NATS connection.
func (n *NATSClient) Close() {
	if n == nil || n.Conn == nil {
		return
	}
	_ = n.Conn.Drain()
	n.Conn.Close()
}
