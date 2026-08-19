package vendors

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
	r.Get("/me/orders", h.ListOrders)
	r.Get("/me/stats", h.GetStats)

	return r
}

// GetProfile returns the authenticated vendor's profile.
func (h *Handler) GetProfile(w http.ResponseWriter, r *http.Request) {
	vendorID := middleware.GetUserID(r.Context())
	if vendorID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	vendor, err := h.service.GetProfile(r.Context(), vendorID)
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "VENDOR_NOT_FOUND", "Vendor profile not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_VENDOR_FAILED", "Failed to fetch vendor profile", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, vendor)
}

// UpdateProfile updates editable vendor profile fields.
func (h *Handler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	vendorID := middleware.GetUserID(r.Context())
	if vendorID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req UpdateVendorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	vendor, err := h.service.UpdateProfile(r.Context(), vendorID, &req)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_VENDOR_FAILED", "Failed to update vendor profile", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, vendor)
}

// ListOrders returns the vendor's active kitchen orders.
func (h *Handler) ListOrders(w http.ResponseWriter, r *http.Request) {
	vendorID := middleware.GetUserID(r.Context())
	if vendorID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	orders, err := h.service.ListOrders(r.Context(), vendorID)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ORDERS_FAILED", "Failed to fetch orders", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, orders)
}

// GetStats returns the vendor's daily performance metrics.
func (h *Handler) GetStats(w http.ResponseWriter, r *http.Request) {
	vendorID := middleware.GetUserID(r.Context())
	if vendorID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	stats, err := h.service.GetStats(r.Context(), vendorID)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_STATS_FAILED", "Failed to fetch stats", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, stats)
}