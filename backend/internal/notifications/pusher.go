package notifications

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"animeat/backend/internal/config"
	"animeat/backend/internal/database"
)

// Pusher dispatches push notifications to mobile devices.
type Pusher interface {
	SendToUser(ctx context.Context, userID, title, body string, data map[string]string) error
	SendToTokens(ctx context.Context, tokens []string, title, body string, data map[string]string) error
}

type FCMPusher struct {
	db         *database.Postgres
	serverKey  string
	projectID  string
	httpClient *http.Client
}

func NewPusher(db *database.Postgres, cfg *config.Config) Pusher {
	var serverKey, projectID string
	if cfg != nil {
		serverKey = cfg.FCMServerKey
		projectID = cfg.FCMProjectID
	}
	return &FCMPusher{
		db:        db,
		serverKey: serverKey,
		projectID: projectID,
		httpClient: &http.Client{
			Timeout: 5 * time.Second,
		},
	}
}

// SendToUser queries user_device_tokens for active devices and sends push notifications.
func (p *FCMPusher) SendToUser(ctx context.Context, userID, title, body string, data map[string]string) error {
	if p.db == nil || p.db.Pool == nil {
		return nil
	}

	// Query registered tokens for user
	rows, err := p.db.Pool.Query(ctx, `
		SELECT token FROM user_device_tokens WHERE user_id = $1
	`, userID)
	if err != nil {
		slog.Debug("could not query user_device_tokens", "user_id", userID, "error", err)
		return nil
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var tok string
		if err := rows.Scan(&tok); err == nil && tok != "" {
			tokens = append(tokens, tok)
		}
	}

	if len(tokens) == 0 {
		slog.Debug("no registered device tokens for user", "user_id", userID)
		return nil
	}

	return p.SendToTokens(ctx, tokens, title, body, data)
}

// SendToTokens sends an FCM push payload to target device tokens.
// If serverKey is not configured, it logs and gracefully completes (no-op).
func (p *FCMPusher) SendToTokens(ctx context.Context, tokens []string, title, body string, data map[string]string) error {
	if len(tokens) == 0 {
		return nil
	}

	if p.serverKey == "" {
		slog.Debug("FCM not configured; skipping push notification dispatch",
			"tokens_count", len(tokens), "title", title)
		return nil
	}

	// Build standard FCM batch payload
	payload := map[string]interface{}{
		"registration_ids": tokens,
		"notification": map[string]string{
			"title": title,
			"body":  body,
			"sound": "default",
		},
		"data": data,
	}

	jsonBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal FCM payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://fcm.googleapis.com/fcm/send", bytes.NewBuffer(jsonBytes))
	if err != nil {
		return fmt.Errorf("failed to create FCM request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "key="+p.serverKey)

	resp, err := p.httpClient.Do(req)
	if err != nil {
		slog.Warn("FCM dispatch request failed", "error", err)
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		slog.Warn("FCM returned error status", "status", resp.StatusCode)
		return fmt.Errorf("FCM error response: %d", resp.StatusCode)
	}

	slog.Info("FCM push notification sent successfully", "tokens_count", len(tokens), "title", title)
	return nil
}
