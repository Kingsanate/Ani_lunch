package users

import "time"

// User represents a customer profile record.
type User struct {
	ID        string    `json:"id"`
	UserID    *string   `json:"user_id,omitempty"`
	Name      string    `json:"name"`
	Email     string    `json:"email"`
	Phone     string    `json:"phone"`
	Address   string    `json:"address"`
	AvatarURL string    `json:"avatar_url,omitempty"`
	IsAdmin   bool      `json:"is_admin"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// UpdateProfileRequest contains editable user profile fields.
type UpdateProfileRequest struct {
	Name      *string `json:"name"`
	Phone     *string `json:"phone"`
	Address   *string `json:"address"`
	AvatarURL *string `json:"avatar_url"`
}

// PublicUser is the safe external representation (never leaks auth metadata).
type PublicUser struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Email     string `json:"email"`
	Phone     string `json:"phone"`
	Address   string `json:"address"`
	AvatarURL string `json:"avatar_url,omitempty"`
}

// Notification is an inbox entry produced by the NATS notification worker.
type Notification struct {
	ID               string    `json:"id"`
	UserID           string    `json:"user_id"`
	Title            string    `json:"title"`
	Body             string    `json:"body"`
	NotificationType string    `json:"notification_type"`
	EntityType       string    `json:"entity_type,omitempty"`
	EntityID         string    `json:"entity_id,omitempty"`
	IsRead           bool      `json:"is_read"`
	CreatedAt        time.Time `json:"created_at"`
}