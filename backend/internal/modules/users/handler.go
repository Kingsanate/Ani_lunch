package users

import (
	"encoding/json"
	"net/http"
	"strconv"

	"animeat/backend/internal/middleware"
	"animeat/backend/internal/platform"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Routes() chi.Router {
	r := chi.NewRouter()

	r.Get("/me", h.GetProfile)
	r.Put("/me", h.UpdateProfile)
	r.Get("/me/notifications", h.ListNotifications)
	r.Post("/me/notifications/read", h.MarkNotificationsRead)
	r.Post("/me/device-tokens", h.RegisterDeviceToken)
	r.Delete("/me/device-tokens", h.UnregisterDeviceToken)

	return r
}

// ListNotifications returns the user's notification inbox.
func (h *Handler) ListNotifications(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	notifications, err := h.service.ListNotifications(r.Context(), userID, limit)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_NOTIFICATIONS_FAILED", "Failed to fetch notifications", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, notifications)
}

// MarkNotificationsRead marks all of the user's notifications as read.
func (h *Handler) MarkNotificationsRead(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	if err := h.service.MarkNotificationsRead(r.Context(), userID); err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "MARK_READ_FAILED", "Failed to mark notifications read", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, map[string]string{"message": "Notifications marked as read"})
}

// GetProfile returns the authenticated user's profile.
func (h *Handler) GetProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	user, err := h.service.GetProfile(r.Context(), userID)
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "USER_NOT_FOUND", "Profile not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_PROFILE_FAILED", "Failed to fetch profile", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, user)
}

// UpdateProfile updates editable profile fields (or creates the profile on first login).
func (h *Handler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	email := ""
	if claims, ok := r.Context().Value(middleware.ClaimsContextKey).(*middleware.CustomClaims); ok {
		email = claims.Email
	}

	user, err := h.service.UpsertProfile(r.Context(), userID, email, &req)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_PROFILE_FAILED", "Failed to update profile", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, user)
}

type DeviceTokenRequest struct {
	Token    string `json:"token"`
	Platform string `json:"platform"` // "android", "ios", "web"
}

// RegisterDeviceToken associates an FCM push token with the authenticated user.
func (h *Handler) RegisterDeviceToken(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req DeviceTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Token == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Device token is required", "")
		return
	}

	if err := h.service.RegisterDeviceToken(r.Context(), userID, req.Token, req.Platform); err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "REGISTRATION_FAILED", "Could not register device token", err.Error())
		return
	}

	platform.RespondJSON(w, http.StatusOK, map[string]string{"status": "registered"})
}

// UnregisterDeviceToken removes a device token when the user logs out.
func (h *Handler) UnregisterDeviceToken(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req DeviceTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Token == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Device token is required", "")
		return
	}

	if err := h.service.UnregisterDeviceToken(r.Context(), userID, req.Token); err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "UNREGISTRATION_FAILED", "Could not unregister device token", err.Error())
		return
	}

	platform.RespondJSON(w, http.StatusOK, map[string]string{"status": "unregistered"})
}