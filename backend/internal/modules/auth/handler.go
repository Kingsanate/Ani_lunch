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
		"POST /api/v1/auth/register":   h.Register,
		"POST /api/v1/auth/login":      h.Login,
		"GET /api/v1/auth/me":          h.Me,
		"POST /api/v1/auth/exchange":   h.Exchange,
		"POST /api/v1/auth/refresh":    h.Refresh,
		"POST /api/v1/auth/logout":     h.Logout,
	}
}

type registerRequest struct {
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Name     string `json:"name"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

// Register creates a new user account directly via Go.
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req registerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "invalid request body", "")
		return
	}
	access, refresh, user, err := h.service.Register(r.Context(), req.Email, req.Phone, req.Name, req.Password, req.Role)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "REGISTER_FAILED", err.Error(), "")
		return
	}
	platform.RespondJSON(w, http.StatusCreated, map[string]interface{}{
		"access_token":  access,
		"refresh_token": refresh,
		"token_type":    "Bearer",
		"expires_in":    900,
		"user":          user,
	})
}

type loginRequest struct {
	Identifier string `json:"identifier"`
	Email      string `json:"email"`
	Phone      string `json:"phone"`
	Password   string `json:"password"`
}

// Login authenticates a user by email/phone + password.
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "invalid request body", "")
		return
	}
	ident := req.Identifier
	if ident == "" {
		if req.Email != "" {
			ident = req.Email
		} else {
			ident = req.Phone
		}
	}
	access, refresh, user, err := h.service.Login(r.Context(), ident, req.Password)
	if err != nil {
		platform.RespondError(w, http.StatusUnauthorized, "LOGIN_FAILED", err.Error(), "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]interface{}{
		"access_token":  access,
		"refresh_token": refresh,
		"token_type":    "Bearer",
		"expires_in":    900,
		"user":          user,
	})
}

// Me returns the profile of the authenticated user.
func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}
	user, err := h.service.GetMe(r.Context(), userID)
	if err != nil {
		platform.RespondError(w, http.StatusNotFound, "USER_NOT_FOUND", "user profile not found", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, user)
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