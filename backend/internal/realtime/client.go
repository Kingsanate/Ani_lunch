package realtime

import (
	"context"
	"encoding/json"
	"log/slog"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = 30 * time.Second
	maxMessageSize = 4096
	// sendBuffer is the outbound queue per client. Events beyond this are
	// dropped and the client is disconnected (slow-consumer protection).
	sendBuffer = 64
)

// clientMessage is the control protocol: {"type":"join","channel":"..."}.
type clientMessage struct {
	Type    string `json:"type"`
	Channel string `json:"channel"`
}

// serverMessage is the event frame pushed to clients.
type serverMessage struct {
	Type    string          `json:"type"`
	Channel string          `json:"channel,omitempty"`
	Data    json.RawMessage `json:"data,omitempty"`
	Message string          `json:"message,omitempty"`
}

// Client is a single authenticated WebSocket connection.
type Client struct {
	hub  *Hub
	conn *websocket.Conn

	userID string
	role   string

	send      chan []byte
	channels  map[string]struct{}
	mu        sync.Mutex
	closed    chan struct{}
	closeOnce sync.Once
}

// NewClient wraps an upgraded WebSocket connection with hub plumbing.
func NewClient(hub *Hub, conn *websocket.Conn, userID, role string) *Client {
	return &Client{
		hub:      hub,
		conn:     conn,
		userID:   userID,
		role:     role,
		send:     make(chan []byte, sendBuffer),
		channels: make(map[string]struct{}),
		closed:   make(chan struct{}),
	}
}

// Serve runs the read/write pumps until the connection ends.
func (c *Client) Serve(ctx context.Context) {
	c.hub.Register(c)
	defer func() {
		c.hub.Unregister(c)
		_ = c.conn.Close()
	}()

	go c.writePump()
	c.readPump(ctx)
}

// readPump consumes control frames: join/leave/ping.
func (c *Client) readPump(ctx context.Context) {
	defer func() {
		c.closeOnce.Do(func() { close(c.closed) })
	}()
	c.conn.SetReadLimit(maxMessageSize)
	_ = c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		return c.conn.SetReadDeadline(time.Now().Add(pongWait))
	})

	for {
		_, data, err := c.conn.ReadMessage()
		if err != nil {
			return
		}

		var msg clientMessage
		if err := json.Unmarshal(data, &msg); err != nil {
			c.enqueue(serverMessage{Type: "error", Message: "invalid message"})
			continue
		}

		switch msg.Type {
		case "ping":
			c.enqueue(serverMessage{Type: "pong"})
		case "join":
			if msg.Channel == "" {
				c.enqueue(serverMessage{Type: "error", Message: "channel required"})
				continue
			}
			allowed, err := c.hub.Authorize(ctx, c.userID, msg.Channel)
			if err != nil {
				slog.Warn("channel authz error", "user", c.userID, "channel", msg.Channel, "error", err)
				c.enqueue(serverMessage{Type: "error", Message: "authorization unavailable"})
				continue
			}
			if !allowed {
				c.enqueue(serverMessage{Type: "error", Message: "forbidden"})
				continue
			}
			c.hub.Join(c, msg.Channel)
			c.enqueue(serverMessage{Type: "joined", Channel: msg.Channel})
		case "leave":
			if msg.Channel != "" {
				c.hub.Leave(c, msg.Channel)
			}
		}
	}
}

// writePump flushes queued events; sends pings on an interval.
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.closeOnce.Do(func() { close(c.closed) })
		_ = c.conn.Close()
	}()

	for {
		select {
		case <-c.closed:
			return
		case payload, ok := <-c.send:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, payload); err != nil {
				return
			}
		case <-ticker.C:
			_ = c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// enqueue serializes a control message into the outbound queue.
func (c *Client) enqueue(msg serverMessage) {
	payload, err := json.Marshal(msg)
	if err != nil {
		return
	}
	select {
	case c.send <- payload:
	default:
	}
}

// UserID returns the authenticated user's ID.
func (c *Client) UserID() string { return c.userID }
