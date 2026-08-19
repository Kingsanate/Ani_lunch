package auth

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// Denylist stores revoked token IDs (jti) and refresh token invalidations in
// Redis. Because API instances are stateless, revocation must be shared.
type Denylist struct {
	client *redis.Client
}

// NewDenylist constructs a token denylist backed by Redis.
func NewDenylist(client *redis.Client) *Denylist {
	return &Denylist{client: client}
}

// RevokeAccessToken adds a token's jti to the denylist until its natural expiry.
// If ttl <= 0 the token is revoked for a default safety window.
func (d *Denylist) RevokeAccessToken(ctx context.Context, jti string, ttl time.Duration) error {
	if d.client == nil {
		return nil // Redis optional in dev; fail open.
	}
	if ttl <= 0 {
		ttl = AccessTokenTTL
	}
	key := "denylist:access:" + jti
	return d.client.Set(ctx, key, 1, ttl).Err()
}

// IsAccessTokenRevoked reports whether a token jti has been revoked.
func (d *Denylist) IsAccessTokenRevoked(ctx context.Context, jti string) (bool, error) {
	if d.client == nil {
		return false, nil
	}
	n, err := d.client.Exists(ctx, "denylist:access:"+jti).Result()
	if err != nil {
		return false, fmt.Errorf("denylist lookup failed: %w", err)
	}
	return n > 0, nil
}

// RevokeRefreshToken invalidates a refresh token id for its full TTL.
func (d *Denylist) RevokeRefreshToken(ctx context.Context, refreshID string) error {
	if d.client == nil {
		return nil
	}
	key := "denylist:refresh:" + refreshID
	return d.client.Set(ctx, key, 1, RefreshTokenTTL).Err()
}

// IsRefreshTokenRevoked reports whether a refresh token id has been revoked.
func (d *Denylist) IsRefreshTokenRevoked(ctx context.Context, refreshID string) (bool, error) {
	if d.client == nil {
		return false, nil
	}
	n, err := d.client.Exists(ctx, "denylist:refresh:"+refreshID).Result()
	if err != nil {
		return false, fmt.Errorf("denylist lookup failed: %w", err)
	}
	return n > 0, nil
}

// StoreRefreshToken persists a refresh token id keyed by user for later
// revocation of all sessions on password change / logout-everywhere.
func (d *Denylist) StoreRefreshToken(ctx context.Context, userID, refreshID string) error {
	if d.client == nil {
		return nil
	}
	key := "refresh:" + userID + ":" + refreshID
	return d.client.Set(ctx, key, 1, RefreshTokenTTL).Err()
}

// RevokeAllUserSessions drops every refresh token for a user (logout everywhere).
func (d *Denylist) RevokeAllUserSessions(ctx context.Context, userID string) error {
	if d.client == nil {
		return nil
	}
	pattern := "refresh:" + userID + ":*"
	iter := d.client.Scan(ctx, 0, pattern, 0).Iterator()
	for iter.Next(ctx) {
		if err := d.client.Del(ctx, iter.Val()).Err(); err != nil {
			return err
		}
	}
	return iter.Err()
}
