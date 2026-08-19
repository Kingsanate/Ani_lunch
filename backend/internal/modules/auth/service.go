package auth

import (
	"context"
	"errors"
	"time"

	"animeat/backend/internal/auth"
	"animeat/backend/internal/authz"
	"animeat/backend/internal/cache"
	"animeat/backend/internal/database"
)

// Service bridges Supabase-issued JWTs (short-term) with Go-issued
// short-lived access tokens + refresh tokens backed by a Redis denylist.
// It resolves the real role from the database so authorization never trusts
// the Supabase "authenticated" claim.
type Service struct {
	db       *database.Postgres
	cache    *cache.RedisClient
	denylist *auth.Denylist
	goSecret string
}

func NewService(db *database.Postgres, cache *cache.RedisClient, goSecret string) *Service {
	return &Service{
		db:       db,
		cache:    cache,
		denylist: auth.NewDenylist(cache.Client),
		goSecret: goSecret,
	}
}

// Denylist exposes the token revocation store so RequireAuth can reject
// revoked access tokens at the middleware boundary.
func (s *Service) Denylist() *auth.Denylist {
	return s.denylist
}

// ExchangeSupabaseToken validates a Supabase JWT (signed with the Supabase
// JWT secret) and returns a Go-issued short-lived access token + refresh token.
// Role is resolved from the database, never from the token claim.
func (s *Service) ExchangeSupabaseToken(ctx context.Context, supabaseToken, supabaseSecret string) (accessToken, refreshToken string, err error) {
	claims, err := auth.ValidateSupabaseToken(supabaseSecret, supabaseToken)
	if err != nil {
		return "", "", err
	}
	if claims.UserID == "" {
		return "", "", errors.New("token missing subject")
	}

	role, err := s.resolveRole(ctx, claims.UserID)
	if err != nil {
		return "", "", err
	}

	accessToken, err = auth.IssueAccessToken(s.goSecret, claims.UserID, claims.Email, role)
	if err != nil {
		return "", "", err
	}

	refreshToken = auth.NewRefreshToken()
	if err := s.denylist.StoreRefreshToken(ctx, claims.UserID, refreshToken); err != nil {
		return "", "", err
	}
	return accessToken, refreshToken, nil
}

// Refresh validates a refresh token id (not revoked) and mints a new access
// token, rotating the refresh token each time.
func (s *Service) Refresh(ctx context.Context, userID, refreshToken string) (accessToken, newRefreshToken string, err error) {
	revoked, err := s.denylist.IsRefreshTokenRevoked(ctx, refreshToken)
	if err != nil {
		return "", "", err
	}
	if revoked {
		return "", "", errors.New("refresh token revoked")
	}

	role, err := s.resolveRole(ctx, userID)
	if err != nil {
		return "", "", err
	}

	accessToken, err = auth.IssueAccessToken(s.goSecret, userID, "", role)
	if err != nil {
		return "", "", err
	}

	// Rotate: revoke old, issue new.
	if err := s.denylist.RevokeRefreshToken(ctx, refreshToken); err != nil {
		return "", "", err
	}
	newRefreshToken = auth.NewRefreshToken()
	if err := s.denylist.StoreRefreshToken(ctx, userID, newRefreshToken); err != nil {
		return "", "", err
	}
	return accessToken, newRefreshToken, nil
}

// Logout revokes the current access token (jti), the given refresh token
// (single session) and optionally every session for the user.
func (s *Service) Logout(ctx context.Context, userID, accessJTI, refreshToken string, allSessions bool) error {
	if accessJTI != "" {
		if err := s.denylist.RevokeAccessToken(ctx, accessJTI, 0); err != nil {
			return err
		}
	}
	if allSessions {
		return s.denylist.RevokeAllUserSessions(ctx, userID)
	}
	return s.denylist.RevokeRefreshToken(ctx, refreshToken)
}

func (s *Service) resolveRole(ctx context.Context, userID string) (string, error) {
	if s.db == nil || s.db.Pool == nil {
		return "customer", nil // default when DB unavailable
	}
	actor, err := authz.ResolveActor(ctx, s.db.Pool, userID)
	if err != nil {
		// Unknown role defaults to customer; do not fail the whole exchange.
		return "customer", nil
	}
	return string(actor), nil
}

var _ = time.Now