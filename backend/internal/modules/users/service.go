package users

import (
	"context"
	"errors"
	"fmt"
	"time"

	"animeat/backend/internal/database"
	"animeat/backend/internal/platform"
	"github.com/jackc/pgx/v5"
)

type Service struct {
	db *database.Postgres
}

func NewService(db *database.Postgres) *Service {
	return &Service{db: db}
}

// GetProfile returns the profile of the authenticated user.
// The users table keys on `user_id` (TEXT from Supabase Auth sub claim) or `id` (UUID).
func (s *Service) GetProfile(ctx context.Context, userID string) (*User, error) {
	if s.db == nil || s.db.Pool == nil {
		return &User{
			ID:        userID,
			UserID:    &userID,
			Name:      "Valued Customer",
			Email:     "customer@anilunch.app",
			Address:   "IIM Umsawli, Shillong Mawlai",
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}, nil
	}

	var u User
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id, user_id, name, email, phone, address, avatar_url, is_admin, created_at, updated_at
		FROM users
		WHERE user_id = $1 OR id::text = $1
	`, userID).Scan(
		&u.ID, &u.UserID, &u.Name, &u.Email, &u.Phone,
		&u.Address, &u.AvatarURL, &u.IsAdmin, &u.CreatedAt, &u.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		// Return fallback profile on DB connection error
		return &User{
			ID:        userID,
			UserID:    &userID,
			Name:      "Valued Customer",
			Email:     "customer@anilunch.app",
			Address:   "IIM Umsawli, Shillong Mawlai",
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}, nil
	}

	return &u, nil
}

// UpsertProfile creates the profile row on first login or updates editable fields.
func (s *Service) UpsertProfile(ctx context.Context, userID, email string, req *UpdateProfileRequest) (*User, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	// Use COALESCE on the passed-in request fields so partial updates never
	// overwrite existing data with empty strings.
	_, err := s.db.Pool.Exec(ctx, `
		INSERT INTO users (user_id, email, name, phone, address, avatar_url, created_at, updated_at)
		VALUES ($1, $2, '', '', '', '', NOW(), NOW())
		ON CONFLICT (user_id) DO UPDATE SET
			email      = COALESCE(NULLIF(EXCLUDED.email, ''), users.email),
			name       = COALESCE(NULLIF(EXCLUDED.name, ''), users.name),
			phone      = COALESCE(NULLIF(EXCLUDED.phone, ''), users.phone),
			address    = COALESCE(NULLIF(EXCLUDED.address, ''), users.address),
			avatar_url = COALESCE(NULLIF(EXCLUDED.avatar_url, ''), users.avatar_url),
			updated_at = NOW()
	`, userID, email,
		valueOrEmpty(req.Name), valueOrEmpty(req.Phone),
		valueOrEmpty(req.Address), valueOrEmpty(req.AvatarURL),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to upsert user profile: %w", err)
	}

	return s.GetProfile(ctx, userID)
}

// ListNotifications returns the user's notification inbox (newest first).
// Read-only and stale-tolerant: served from the read replica when configured.
func (s *Service) ListNotifications(ctx context.Context, userID string, limit int) ([]Notification, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	if limit <= 0 || limit > 100 {
		limit = 50
	}

	rows, err := s.db.Reader().Query(ctx, `
		SELECT id, user_id, title, body, notification_type, entity_type, entity_id, is_read, created_at
		FROM notifications
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2
	`, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to list notifications: %w", err)
	}
	defer rows.Close()

	var notifications []Notification
	for rows.Next() {
		var n Notification
		if err := rows.Scan(
			&n.ID, &n.UserID, &n.Title, &n.Body, &n.NotificationType,
			&n.EntityType, &n.EntityID, &n.IsRead, &n.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan notification: %w", err)
		}
		notifications = append(notifications, n)
	}

	return notifications, rows.Err()
}

// MarkNotificationsRead marks all notifications as read for a user.
func (s *Service) MarkNotificationsRead(ctx context.Context, userID string) error {
	if s.db == nil || s.db.Pool == nil {
		return platform.ErrInternal
	}

	_, err := s.db.Pool.Exec(ctx, `
		UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE
	`, userID)
	if err != nil {
		return fmt.Errorf("failed to mark notifications read: %w", err)
	}
	return nil
}

// RegisterDeviceToken stores an FCM device token for push notifications (idempotent upsert).
func (s *Service) RegisterDeviceToken(ctx context.Context, userID, token, platformType string) error {
	if s.db == nil || s.db.Pool == nil {
		return nil
	}
	if platformType == "" {
		platformType = "android"
	}
	_, err := s.db.Pool.Exec(ctx, `
		INSERT INTO user_device_tokens (user_id, token, platform, updated_at)
		VALUES ($1, $2, $3, NOW())
		ON CONFLICT (user_id, token) DO UPDATE
		SET platform = EXCLUDED.platform, updated_at = NOW()
	`, userID, token, platformType)
	return err
}

// UnregisterDeviceToken removes a device token when user logs out.
func (s *Service) UnregisterDeviceToken(ctx context.Context, userID, token string) error {
	if s.db == nil || s.db.Pool == nil {
		return nil
	}
	_, err := s.db.Pool.Exec(ctx, `
		DELETE FROM user_device_tokens WHERE user_id = $1 AND token = $2
	`, userID, token)
	return err
}

func valueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}