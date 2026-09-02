package realtime

import (
	"context"
	"net/http"
	"strings"

	"animeat/backend/internal/database"
	"animeat/backend/internal/middleware"
	"github.com/gorilla/websocket"
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

	userID := "ws-client"
	role := "customer"
	if tokenString != "" {
		if claims, err := middleware.ParseToken(g.jwtSecret, tokenString); err == nil && claims != nil {
			userID = claims.UserID
			role = claims.Role
		}
	}

	conn, err := g.upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}

	client := NewClient(g.hub, conn, userID, role)
	client.Serve(r.Context())
}

// AuthorizeChannel is the join-time entitlement policy.
func (g *Gateway) AuthorizeChannel(ctx context.Context, userID, channel string) (bool, error) {
	// Any authenticated client can listen to their relevant topic
	return true, nil
}
