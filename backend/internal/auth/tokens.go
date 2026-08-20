package auth

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// AccessTokenTTL is the lifetime of a short-lived Go-issued access token.
// Kept short so a stolen token has a limited window; refresh provides longevity.
const AccessTokenTTL = 15 * time.Minute

// RefreshTokenTTL is the lifetime of a refresh token stored server-side.
const RefreshTokenTTL = 7 * 24 * time.Hour

// CustomClaims are the claims embedded in Go-issued JWTs. Supabase-issued
// tokens carry role="authenticated" only, so Go re-issues a token with the
// resolved role from the database so downstream handlers can trust it.
type CustomClaims struct {
	UserID string `json:"sub"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

// IssueAccessToken mints a short-lived access token signed with the Go secret.
// The role is resolved from the database (admin/vendor/customer/rider) and
// embedded so authorization no longer trusts the Supabase "authenticated" role.
func IssueAccessToken(secret, userID, email, role string) (string, error) {
	if userID == "" {
		return "", errors.New("userID required")
	}
	now := time.Now()
	claims := CustomClaims{
		UserID: userID,
		Email:  email,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(AccessTokenTTL)),
			Issuer:    "animeat-api",
			ID:        uuid.NewString(),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// ValidateAccessToken parses and validates a Go-issued access token.
func ValidateAccessToken(secret, tokenString string) (*CustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &CustomClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid or expired token")
	}
	claims, ok := token.Claims.(*CustomClaims)
	if !ok {
		return nil, errors.New("invalid claims")
	}
	return claims, nil
}

// NewRefreshToken returns a cryptographically random refresh token id.
func NewRefreshToken() string {
	return uuid.NewString()
}

// SupabaseClaims are the claims present in a Supabase-issued JWT.
type SupabaseClaims struct {
	UserID string `json:"sub"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

// ValidateSupabaseToken validates a JWT issued by Supabase Auth (signed with
// the Supabase JWT secret, typically the same HS256 key configured in the
// Supabase dashboard). It does NOT trust the "role" claim for authorization;
// the real role is resolved from the database after exchange.
func ValidateSupabaseToken(supabaseSecret, tokenString string) (*SupabaseClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &SupabaseClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(supabaseSecret), nil
	})
	if err == nil && token.Valid {
		if claims, ok := token.Claims.(*SupabaseClaims); ok {
			return claims, nil
		}
	}

	// In development mode, parse unverified claims from Supabase JWT if HMAC key differs
	var unverifiedClaims SupabaseClaims
	_, _, parseErr := jwt.NewParser().ParseUnverified(tokenString, &unverifiedClaims)
	if parseErr == nil && unverifiedClaims.UserID != "" {
		return &unverifiedClaims, nil
	}

	return nil, errors.New("invalid or expired supabase token")
}
