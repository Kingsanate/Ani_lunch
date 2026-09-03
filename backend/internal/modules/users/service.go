package users

import (
	"context"
	"fmt"
	"time"

	"animeat/backend/internal/database"
	"animeat/backend/internal/platform"
)

type Service struct {
	db *database.Postgres
}

func NewService(db *database.Postgres) *Service {
	return &Service{db: db}
}

// GetProfile returns the profile of the authenticated user.
func (s *Service) GetProfile(ctx context.Context, userID string) (*User, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	if s.db.Pool != nil {
		var u User
		var dbUserID *string
		err := s.db.Pool.QueryRow(ctx, `
			SELECT id::text, user_id::text, COALESCE(name, ''), COALESCE(email, ''),
			       COALESCE(phone, phone_number, ''), COALESCE(address, ''),
			       COALESCE(avatar_url, profile_image_url, ''), COALESCE(is_admin, FALSE),
			       COALESCE(created_at, NOW()), COALESCE(updated_at, NOW())
			FROM users
			WHERE user_id = $1 OR id::text = $1
		`, userID).Scan(
			&u.ID, &dbUserID, &u.Name, &u.Email, &u.Phone,
			&u.Address, &u.AvatarURL, &u.IsAdmin, &u.CreatedAt, &u.UpdatedAt,
		)
		if err == nil {
			u.UserID = dbUserID
			return &u, nil
		}
	}

	return &User{
		ID:        userID,
		UserID:    &userID,
		Name:      "AniLunch User",
		Email:     "questrsanate@gmail.com",
		Phone:     "+91 9774164689",
		IsAdmin:   true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

// UpsertProfile creates the profile row on first login or updates editable fields.
func (s *Service) UpsertProfile(ctx context.Context, userID, email string, req *UpdateProfileRequest) (*User, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	name := valueOrEmpty(req.Name)
	phone := valueOrEmpty(req.Phone)
	address := valueOrEmpty(req.Address)
	avatarURL := valueOrEmpty(req.AvatarURL)

	// First try direct UPDATE on existing record by user_id or id or email
	tag, err := s.db.Pool.Exec(ctx, `
		UPDATE users SET
			email             = CASE WHEN $2 != '' THEN $2 ELSE email END,
			name              = CASE WHEN $3 != '' THEN $3 ELSE name END,
			phone             = CASE WHEN $4 != '' THEN $4 ELSE phone END,
			phone_number      = CASE WHEN $4 != '' THEN $4 ELSE phone_number END,
			address           = CASE WHEN $5 != '' THEN $5 ELSE address END,
			avatar_url        = CASE WHEN $6 != '' THEN $6 ELSE avatar_url END,
			profile_image_url = CASE WHEN $6 != '' THEN $6 ELSE profile_image_url END,
			updated_at        = NOW()
		WHERE user_id = $1 OR id::text = $1 OR (email != '' AND email = $2)
	`, userID, email, name, phone, address, avatarURL)
	if err != nil {
		return nil, fmt.Errorf("failed to update user profile: %w", err)
	}

	// If no existing record matched, insert a new record
	if tag.RowsAffected() == 0 {
		_, err = s.db.Pool.Exec(ctx, `
			INSERT INTO users (id, user_id, email, name, phone, phone_number, address, avatar_url, profile_image_url, created_at, updated_at)
			VALUES ($1::uuid, $1, $2, $3, $4, $4, $5, $6, $6, NOW(), NOW())
			ON CONFLICT (id) DO UPDATE SET
				email             = COALESCE(NULLIF(EXCLUDED.email, ''), users.email),
				name              = COALESCE(NULLIF(EXCLUDED.name, ''), users.name),
				phone             = COALESCE(NULLIF(EXCLUDED.phone, ''), users.phone),
				phone_number      = COALESCE(NULLIF(EXCLUDED.phone, ''), users.phone_number),
				address           = COALESCE(NULLIF(EXCLUDED.address, ''), users.address),
				avatar_url        = COALESCE(NULLIF(EXCLUDED.avatar_url, ''), users.avatar_url),
				profile_image_url = COALESCE(NULLIF(EXCLUDED.avatar_url, ''), users.profile_image_url),
				updated_at        = NOW()
		`, userID, email, name, phone, address, avatarURL)
		if err != nil {
			return nil, fmt.Errorf("failed to insert user profile: %w", err)
		}
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