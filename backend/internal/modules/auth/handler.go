package auth

import (
	"encoding/json"
	"net/http"

	"animeat/backend/internal/config"
	"animeat/backend/internal/middleware"
	"animeat/backend/internal/platform"
)

type Handler struct {
	service *Service
	cfg     *config.Config
}

func NewHandler(service *Service, cfg *config.Config) *Handler {
	return &Handler{service: service, cfg: cfg}
}

func (h *Handler) Routes() map[string]http.HandlerFunc {
	return map[string]http.HandlerFunc{
		"POST /api/v1/auth/exchange":   h.Exchange,
		"POST /api/v1/auth/refresh":    h.Refresh,
		"POST /api/v1/auth/logout":     h.Logout,
	}
}

type exchangeRequest struct {
	SupabaseToken string `json:"supabase_token"`
}

// Exchange swaps a Supabase session JWT for Go short-lived tokens.
func (h *Handler) Exchange(w http.ResponseWriter, r *http.Request) {
	var req exchangeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.SupabaseToken == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "supabase_token required", "")
		return
	}
	access, refresh, err := h.service.ExchangeSupabaseToken(r.Context(), req.SupabaseToken, h.cfg.SupabaseJWTSecret)
	if err != nil {
		platform.RespondError(w, http.StatusUnauthorized, "EXCHANGE_FAILED", err.Error(), "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]string{
		"access_token":  access,
		"refresh_token": refresh,
		"token_type":    "Bearer",
		"expires_in":    "900",
	})
}

type refreshRequest struct {
	UserID       string `json:"user_id"`
	RefreshToken string `json:"refresh_token"`
}

// Refresh rotates tokens.
func (h *Handler) Refresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.RefreshToken == "" || req.UserID == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "user_id and refresh_token required", "")
		return
	}
	access, newRefresh, err := h.service.Refresh(r.Context(), req.UserID, req.RefreshToken)
	if err != nil {
		platform.RespondError(w, http.StatusUnauthorized, "REFRESH_FAILED", err.Error(), "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]string{
		"access_token":  access,
		"refresh_token": newRefresh,
		"token_type":    "Bearer",
		"expires_in":    "900",
	})
}

type logoutRequest struct {
	RefreshToken string `json:"refresh_token"`
	AllSessions  bool   `json:"all_sessions"`
}

// Logout revokes the access token used for this request plus refresh token(s).
func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}
	var req logoutRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	// Revoke the current access token (jti) immediately so it dies even
	// within its 15-minute window.
	var jti string
	if claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*middleware.CustomClaims); ok {
		jti = claims.ID
	}

	if err := h.service.Logout(r.Context(), userID, jti, req.RefreshToken, req.AllSessions); err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "LOGOUT_FAILED", err.Error(), "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]string{"message": "logged out"})
}