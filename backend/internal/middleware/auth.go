package middleware

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"animeat/backend/internal/platform"
	"github.com/golang-jwt/jwt/v5"
)

const (
	UserIDContextKey contextKey = "user_id"
	RoleContextKey   contextKey = "user_role"
	ClaimsContextKey contextKey = "jwt_claims"
)

type CustomClaims struct {
	UserID string `json:"sub"`
	Email  string `json:"email"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

// AccessTokenRevoker reports whether a token's jti has been revoked.
// Implemented by auth.Denylist (Redis-backed) and injected without an import
// cycle. A nil revoker fails open (dev mode / Redis optional).
type AccessTokenRevoker interface {
	IsAccessTokenRevoked(ctx context.Context, jti string) (bool, error)
}

// RequireAuth validates the Bearer JWT in the Authorization header and
// rejects revoked access tokens (jti denylist) when a revoker is provided.
func RequireAuth(jwtSecret string, revoker AccessTokenRevoker) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Missing Authorization header", "")
				return
			}

			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
				platform.RespondError(w, http.StatusUnauthorized, "INVALID_TOKEN", "Malformed Authorization header", "")
				return
			}

			tokenString := parts[1]
			token, err := jwt.ParseWithClaims(tokenString, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, errors.New("unexpected signing method")
				}
				return []byte(jwtSecret), nil
			})

			if err != nil || !token.Valid {
				platform.RespondError(w, http.StatusUnauthorized, "INVALID_TOKEN", "Token is invalid or expired", "")
				return
			}

			claims, ok := token.Claims.(*CustomClaims)
			if !ok {
				platform.RespondError(w, http.StatusUnauthorized, "INVALID_CLAIMS", "Could not parse token claims", "")
				return
			}

			if revoker != nil && claims.ID != "" {
				revoked, revErr := revoker.IsAccessTokenRevoked(r.Context(), claims.ID)
				if revErr != nil {
					slog.Warn("access token revocation check failed", "error", revErr)
					platform.RespondError(w, http.StatusServiceUnavailable, "REVOCATION_CHECK_FAILED", "Could not verify token status", "")
					return
				}
				if revoked {
					platform.RespondError(w, http.StatusUnauthorized, "TOKEN_REVOKED", "Token has been revoked", "")
					return
				}
			}

			ctx := context.WithValue(r.Context(), UserIDContextKey, claims.UserID)
			ctx = context.WithValue(ctx, RoleContextKey, claims.Role)
			ctx = context.WithValue(ctx, ClaimsContextKey, claims)

			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// RequireRole ensures that the authenticated user possesses at least one of the allowed roles.
func RequireRole(allowedRoles ...string) func(http.Handler) http.Handler {
	roleMap := make(map[string]bool, len(allowedRoles))
	for _, r := range allowedRoles {
		roleMap[r] = true
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			role, _ := r.Context().Value(RoleContextKey).(string)
			if !roleMap[role] && !roleMap["*"] {
				platform.RespondError(w, http.StatusForbidden, "FORBIDDEN", "You do not have permission to access this resource", "")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// ParseToken validates a raw JWT and returns its claims. Reused by the
// realtime WebSocket gateway, which receives tokens via query parameter
// (browser clients cannot set headers on WebSocket upgrades).
func ParseToken(jwtSecret, tokenString string) (*CustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(jwtSecret), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("token is invalid or expired")
	}
	claims, ok := token.Claims.(*CustomClaims)
	if !ok {
		return nil, errors.New("could not parse token claims")
	}
	return claims, nil
}

// GetUserID extracts the user ID from the request context.
func GetUserID(ctx context.Context) string {
	if val, ok := ctx.Value(UserIDContextKey).(string); ok {
		return val
	}
	return ""
}

// GetRole extracts the user role from the request context.
func GetRole(ctx context.Context) string {
	if val, ok := ctx.Value(RoleContextKey).(string); ok {
		return val
	}
	return ""
}
