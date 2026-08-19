package riders

import (
	"encoding/json"
	"net/http"

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
	r.Put("/me/availability", h.SetAvailability)
	r.Put("/me/location", h.UpdateLocation)

	r.Get("/orders/available", h.ListAvailableOrders)
	r.Get("/orders/mine", h.ListAssignedOrders)
	r.Post("/orders/{id}/accept", h.AcceptOrder)

	return r
}

// GetProfile returns the authenticated rider's profile.
func (h *Handler) GetProfile(w http.ResponseWriter, r *http.Request) {
	riderID := middleware.GetUserID(r.Context())
	if riderID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	rider, err := h.service.GetProfile(r.Context(), riderID)
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "RIDER_NOT_FOUND", "Rider profile not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_RIDER_FAILED", "Failed to fetch rider profile", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, rider)
}

// UpdateProfile updates the rider's editable profile fields.
func (h *Handler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	riderID := middleware.GetUserID(r.Context())
	if riderID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	rider, err := h.service.UpsertProfile(r.Context(), riderID, &req)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_RIDER_FAILED", "Failed to update rider profile", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, rider)
}

// SetAvailability toggles the rider online/offline state.
func (h *Handler) SetAvailability(w http.ResponseWriter, r *http.Request) {
	riderID := middleware.GetUserID(r.Context())
	if riderID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req AvailabilityUpdate
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	rider, err := h.service.SetAvailability(r.Context(), riderID, req.IsOnline)
	if err != nil {
		if err == platform.ErrForbidden {
			platform.RespondError(w, http.StatusForbidden, "RIDER_NOT_APPROVED", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_AVAILABILITY_FAILED", "Failed to update availability", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, rider)
}

// UpdateLocation persists the rider's current GPS coordinates.
func (h *Handler) UpdateLocation(w http.ResponseWriter, r *http.Request) {
	riderID := middleware.GetUserID(r.Context())
	if riderID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req LocationUpdate
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	rider, err := h.service.UpdateLocation(r.Context(), riderID, req)
	if err != nil {
		if err == platform.ErrInvalidInput {
			platform.RespondError(w, http.StatusBadRequest, "INVALID_COORDINATES", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_LOCATION_FAILED", "Failed to update location", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, rider)
}

// ListAvailableOrders returns unassigned ready_for_pickup orders.
func (h *Handler) ListAvailableOrders(w http.ResponseWriter, r *http.Request) {
	orders, err := h.service.ListAvailableOrders(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ORDERS_FAILED", "Failed to fetch available orders", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, orders)
}

// ListAssignedOrders returns the rider's active assigned orders.
func (h *Handler) ListAssignedOrders(w http.ResponseWriter, r *http.Request) {
	riderID := middleware.GetUserID(r.Context())
	if riderID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	orders, err := h.service.ListAssignedOrders(r.Context(), riderID)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ORDERS_FAILED", "Failed to fetch assigned orders", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, orders)
}

// AcceptOrder claims an unassigned ready_for_pickup order.
func (h *Handler) AcceptOrder(w http.ResponseWriter, r *http.Request) {
	riderID := middleware.GetUserID(r.Context())
	if riderID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	orderID := chi.URLParam(r, "id")
	if orderID == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Order ID required", "")
		return
	}

	order, err := h.service.AcceptOrder(r.Context(), riderID, orderID)
	if err != nil {
		if err == platform.ErrConflict {
			platform.RespondError(w, http.StatusConflict, "ORDER_UNAVAILABLE", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusBadRequest, "ACCEPT_ORDER_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, order)
}