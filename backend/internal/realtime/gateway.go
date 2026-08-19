package realtime

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"animeat/backend/internal/database"
	"animeat/backend/internal/middleware"
	"github.com/gorilla/websocket"
	"github.com/jackc/pgx/v5"
)

// Gateway owns the WebSocket upgrade endpoint and the join-time channel
// entitlement policy.
type Gateway struct {
	hub       *Hub
	jwtSecret string
	db        *database.Postgres
	upgrader  websocket.Upgrader
}

// NewGateway creates the WebSocket handler.
func NewGateway(hub *Hub, jwtSecret string, db *database.Postgres) *Gateway {
	return &Gateway{
		hub:       hub,
		jwtSecret: jwtSecret,
		db:        db,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			// The JWT itself authenticates the socket; any origin may connect
			// as long as it presents a valid token.
			CheckOrigin: func(r *http.Request) bool { return true },
		},
	}
}

// HandleWS upgrades the connection and runs the client session. Auth: the
// JWT is read from the ?token= query parameter (browser-friendly) or the
// Authorization Bearer header (Flutter-friendly).
func (g *Gateway) HandleWS(w http.ResponseWriter, r *http.Request) {
	tokenString := r.URL.Query().Get("token")
	if tokenString == "" {
		authHeader := r.Header.Get("Authorization")
		if parts := strings.SplitN(authHeader, " ", 2); len(parts) == 2 && strings.EqualFold(parts[0], "Bearer") {
			tokenString = parts[1]
		}
	}
	if tokenString == "" {
		http.Error(w, "missing token", http.StatusUnauthorized)
		return
	}

	claims, err := middleware.ParseToken(g.jwtSecret, tokenString)
	if err != nil {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}

	conn, err := g.upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	client := NewClient(g.hub, conn, claims.UserID, claims.Role)
	client.Serve(r.Context())
}

// AuthorizeChannel is the join-time entitlement policy.
func (g *Gateway) AuthorizeChannel(ctx context.Context, userID, channel string) (bool, error) {
	if g.db == nil || g.db.Pool == nil {
		return false, errors.New("database unavailable")
	}

	kind, id, ok := ParseChannel(channel)
	if !ok {
		switch channel {
		case ChannelRiderBroadcast:
			return true, nil // any authenticated user may listen to broadcasts
		case ChannelAdmin:
			// Admin console channel: only users with the is_admin flag.
			var isAdmin bool
			err := g.db.Pool.QueryRow(ctx, `
				SELECT COALESCE(is_admin, FALSE) FROM users
				WHERE user_id = $1 OR id::text = $1
			`, userID).Scan(&isAdmin)
			if err != nil {
				return false, err
			}
			return isAdmin, nil
		}
		return false, nil
	}

	switch kind {
	case ChannelOrder:
		var orderUserID, riderID string
		var vendorID *string
		err := g.db.Pool.QueryRow(ctx, `
			SELECT user_id, COALESCE(rider_id, ''), vendor_id FROM orders WHERE id = $1
		`, id).Scan(&orderUserID, &riderID, &vendorID)
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		if err != nil {
			return false, err
		}
		if userID == orderUserID || userID == riderID {
			return true, nil
		}
		return vendorID != nil && userID == *vendorID, nil

	case ChannelRider:
		// Self, a vendor whose orders this rider serves, a customer with an
		// in-progress order assigned to this rider, or an admin.
		if userID == id {
			return true, nil
		}
		var linked string
		err := g.db.Pool.QueryRow(ctx, `
			SELECT id FROM orders
			WHERE rider_id = $1 AND user_id = $2
			  AND status IN ('ready_for_pickup', 'assigned', 'accepted', 'picked_up')
			LIMIT 1
		`, id, userID).Scan(&linked)
		if err == nil {
			return true, nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return false, err
		}
		err = g.db.Pool.QueryRow(ctx, `
			SELECT id FROM orders
			WHERE rider_id = $1 AND vendor_id = $2
			  AND status IN ('ready_for_pickup', 'assigned', 'accepted', 'picked_up')
			LIMIT 1
		`, id, userID).Scan(&linked)
		if err == nil {
			return true, nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return false, err
		}
		return false, nil

	case ChannelVendor:
		// Single-store mode: vendors.id is the vendor's auth user id.
		var vendorID string
		err := g.db.Pool.QueryRow(ctx, `
			SELECT id FROM vendors WHERE id = $1
		`, id).Scan(&vendorID)
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		if err != nil {
			return false, err
		}
		return userID == id, nil

	default:
		return false, fmt.Errorf("unknown channel kind %q", kind)
	}
}
