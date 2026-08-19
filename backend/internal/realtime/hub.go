package realtime

import (
	"context"
	"sync"
)

// Hub tracks WebSocket clients and the channels they joined. A channel is a
// scoped pub/sub topic like "order:ORD-123", "rider:rider-uuid" or
// "vendor:vendor-uuid". Events published to a channel are fanned out to every
// client currently joined to it — no per-client database queries.
type Hub struct {
	mu       sync.RWMutex
	clients  map[*Client]struct{}
	channels map[string]map[*Client]struct{}

	// authorize decides whether a user may join a channel. Implementations
	// resolve entitlement against the database at join time only.
	authorize func(ctx context.Context, userID, channel string) (bool, error)
}

// NewHub creates a hub with the given join-time authorization policy.
func NewHub(authorize func(ctx context.Context, userID, channel string) (bool, error)) *Hub {
	return &Hub{
		clients:   make(map[*Client]struct{}),
		channels:  make(map[string]map[*Client]struct{}),
		authorize: authorize,
	}
}

// Authorize exposes the join-time authorization policy.
func (h *Hub) Authorize(ctx context.Context, userID, channel string) (bool, error) {
	if h.authorize == nil {
		return true, nil
	}
	return h.authorize(ctx, userID, channel)
}

// AttachAuthorizer sets the join-time authorization policy (used when the
// policy depends on services created after the hub).
func (h *Hub) AttachAuthorizer(authorize func(ctx context.Context, userID, channel string) (bool, error)) {
	h.authorize = authorize
}

// Register adds a connected client to the hub.
func (h *Hub) Register(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.clients[c] = struct{}{}
}

// Unregister removes a client and drops it from every channel it joined.
func (h *Hub) Unregister(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(h.clients, c)
	for ch := range c.channels {
		if members, ok := h.channels[ch]; ok {
			delete(members, c)
			if len(members) == 0 {
				delete(h.channels, ch)
			}
		}
	}
	c.channels = map[string]struct{}{}
}

// Join subscribes the client to a channel.
func (h *Hub) Join(c *Client, channel string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.channels[channel] == nil {
		h.channels[channel] = make(map[*Client]struct{})
	}
	h.channels[channel][c] = struct{}{}
	c.channels[channel] = struct{}{}
}

// Leave unsubscribes the client from a channel.
func (h *Hub) Leave(c *Client, channel string) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if members, ok := h.channels[channel]; ok {
		delete(members, c)
		if len(members) == 0 {
			delete(h.channels, channel)
		}
	}
	delete(c.channels, channel)
}

// Broadcast delivers an event payload to every client joined to the channel.
// It never blocks on a slow client; overflow clients are evicted instead.
func (h *Hub) Broadcast(channel string, payload []byte) {
	h.mu.RLock()
	members := h.channels[channel]
	if len(members) == 0 {
		h.mu.RUnlock()
		return
	}
	targets := make([]*Client, 0, len(members))
	for c := range members {
		targets = append(targets, c)
	}
	h.mu.RUnlock()

	for _, c := range targets {
		select {
		case c.send <- payload:
		default:
			// Slow consumer: drop the client rather than block the event loop.
			c.closeOnce.Do(func() {
				close(c.closed)
			})
		}
	}
}

// ClientCount returns the number of connected clients (metrics/debug).
func (h *Hub) ClientCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// ChannelCount returns the number of active channels (metrics/debug).
func (h *Hub) ChannelCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.channels)
}
