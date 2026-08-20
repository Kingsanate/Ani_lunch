package notifications

import (
	"bytes"
	"context"
	"crypto/rsa"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"animeat/backend/internal/config"
	"animeat/backend/internal/database"
	"github.com/golang-jwt/jwt/v5"
)

// Pusher dispatches push notifications to mobile devices.
type Pusher interface {
	SendToUser(ctx context.Context, userID, title, body string, data map[string]string) error
	SendToTokens(ctx context.Context, tokens []string, title, body string, data map[string]string) error
}

type serviceAccountKey struct {
	Type        string `json:"type"`
	ProjectID   string `json:"project_id"`
	ClientEmail string `json:"client_email"`
	PrivateKey  string `json:"private_key"`
	TokenURI    string `json:"token_uri"`
}

type FCMPusher struct {
	db         *database.Postgres
	serverKey  string
	projectID  string
	sa         *serviceAccountKey
	parsedKey  *rsa.PrivateKey
	httpClient *http.Client

	// OAuth2 token cache
	tokenMu     sync.Mutex
	cachedToken string
	tokenExpiry time.Time
}

func NewPusher(db *database.Postgres, cfg *config.Config) Pusher {
	p := &FCMPusher{
		db: db,
		httpClient: &http.Client{
			Timeout: 5 * time.Second,
		},
	}

	if cfg == nil {
		return p
	}

	p.serverKey = cfg.FCMServerKey
	p.projectID = cfg.FCMProjectID

	// 1. Try loading from service account JSON string
	if cfg.FCMServiceAccountJSON != "" {
		p.loadServiceAccount([]byte(cfg.FCMServiceAccountJSON))
	} else if cfg.FCMServiceAccountFile != "" {
		// 2. Try loading from service account file
		if data, err := os.ReadFile(cfg.FCMServiceAccountFile); err == nil {
			p.loadServiceAccount(data)
		} else {
			slog.Debug("could not read FCMServiceAccountFile", "path", cfg.FCMServiceAccountFile, "error", err)
		}
	}

	return p
}

func (p *FCMPusher) loadServiceAccount(data []byte) {
	data = bytes.TrimPrefix(data, []byte("\xef\xbb\xbf"))
	var sa serviceAccountKey
	if err := json.Unmarshal(data, &sa); err != nil {
		slog.Warn("failed to parse Firebase service account JSON", "error", err)
		return
	}

	rsaKey, err := jwt.ParseRSAPrivateKeyFromPEM([]byte(sa.PrivateKey))
	if err != nil {
		slog.Warn("failed to parse Firebase RSA private key", "error", err)
		return
	}

	p.sa = &sa
	p.parsedKey = rsaKey
	if p.projectID == "" {
		p.projectID = sa.ProjectID
	}
	slog.Info("Firebase Cloud Messaging HTTP v1 initialized", "project_id", p.projectID, "client_email", sa.ClientEmail)
}

// SendToUser queries user_device_tokens for active devices and sends push notifications.
func (p *FCMPusher) SendToUser(ctx context.Context, userID, title, body string, data map[string]string) error {
	if p.db == nil || p.db.Pool == nil {
		return nil
	}

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

// SendToTokens sends push notifications via FCM HTTP v1 API (or legacy API if server key provided).
func (p *FCMPusher) SendToTokens(ctx context.Context, tokens []string, title, body string, data map[string]string) error {
	if len(tokens) == 0 {
		return nil
	}

	// 1. Prefer modern FCM HTTP v1 API with Service Account credentials
	if p.sa != nil && p.parsedKey != nil && p.projectID != "" {
		return p.sendHTTPv1(ctx, tokens, title, body, data)
	}

	// 2. Fallback to legacy server key if configured
	if p.serverKey != "" {
		return p.sendLegacy(ctx, tokens, title, body, data)
	}

	slog.Debug("FCM not configured; skipping push notification dispatch",
		"tokens_count", len(tokens), "title", title)
	return nil
}

// sendHTTPv1 sends push notifications using the modern FCM v1 API with OAuth2 Bearer token.
func (p *FCMPusher) sendHTTPv1(ctx context.Context, tokens []string, title, body string, data map[string]string) error {
	accessToken, err := p.getOAuth2Token(ctx)
	if err != nil {
		slog.Warn("failed to obtain Firebase OAuth2 token", "error", err)
		return err
	}

	endpoint := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", p.projectID)

	for _, tok := range tokens {
		msgPayload := map[string]interface{}{
			"message": map[string]interface{}{
				"token": tok,
				"notification": map[string]string{
					"title": title,
					"body":  body,
				},
				"data": data,
			},
		}

		jsonBytes, err := json.Marshal(msgPayload)
		if err != nil {
			continue
		}

		req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewBuffer(jsonBytes))
		if err != nil {
			continue
		}

		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+accessToken)

		resp, err := p.httpClient.Do(req)
		if err != nil {
			slog.Warn("FCM HTTP v1 dispatch request failed", "token", tok[:min(len(tok), 10)]+"...", "error", err)
			continue
		}
		resp.Body.Close()

		if resp.StatusCode >= 400 {
			slog.Warn("FCM HTTP v1 returned error status", "status", resp.StatusCode)
		}
	}

	slog.Info("FCM HTTP v1 push notifications dispatched", "tokens_count", len(tokens), "title", title)
	return nil
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// getOAuth2Token fetches and caches a Google OAuth2 access token for FCM scope.
func (p *FCMPusher) getOAuth2Token(ctx context.Context) (string, error) {
	p.tokenMu.Lock()
	defer p.tokenMu.Unlock()

	if p.cachedToken != "" && time.Now().Before(p.tokenExpiry) {
		return p.cachedToken, nil
	}

	tokenURI := p.sa.TokenURI
	if tokenURI == "" {
		tokenURI = "https://oauth2.googleapis.com/token"
	}

	now := time.Now().UTC()
	claims := jwt.MapClaims{
		"iss":   p.sa.ClientEmail,
		"sub":   p.sa.ClientEmail,
		"aud":   tokenURI,
		"scope": "https://www.googleapis.com/auth/firebase.messaging",
		"iat":   now.Unix(),
		"exp":   now.Add(time.Hour).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	tokenString, err := token.SignedString(p.parsedKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign Google JWT assertion: %w", err)
	}

	form := url.Values{}
	form.Set("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer")
	form.Set("assertion", tokenString)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, tokenURI, strings.NewReader(form.Encode()))
	if err != nil {
		return "", fmt.Errorf("failed to create OAuth2 token request: %w", err)
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := p.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("OAuth2 token request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return "", fmt.Errorf("OAuth2 token endpoint returned status %d", resp.StatusCode)
	}

	var oauthResp struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int    `json:"expires_in"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&oauthResp); err != nil {
		return "", fmt.Errorf("failed to decode OAuth2 response: %w", err)
	}

	p.cachedToken = oauthResp.AccessToken
	p.tokenExpiry = now.Add(time.Duration(oauthResp.ExpiresIn-60) * time.Second)

	return p.cachedToken, nil
}

// sendLegacy sends via legacy FCM endpoint (key=SERVER_KEY).
func (p *FCMPusher) sendLegacy(ctx context.Context, tokens []string, title, body string, data map[string]string) error {
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
		return fmt.Errorf("failed to marshal FCM legacy payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://fcm.googleapis.com/fcm/send", bytes.NewBuffer(jsonBytes))
	if err != nil {
		return fmt.Errorf("failed to create legacy FCM request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "key="+p.serverKey)

	resp, err := p.httpClient.Do(req)
	if err != nil {
		slog.Warn("Legacy FCM dispatch failed", "error", err)
		return err
	}
	defer resp.Body.Close()

	slog.Info("Legacy FCM push notifications dispatched", "tokens_count", len(tokens), "title", title)
	return nil
}
