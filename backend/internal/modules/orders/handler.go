package orders

import (
	"encoding/json"
	"errors"
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

	r.Post("/", h.CreateOrder)
	r.Get("/", h.ListOrders)
	r.Post("/{id}/cancel", h.CancelOrder)
	r.Post("/{id}/transition", h.TransitionOrder)
	r.Get("/{id}", h.GetOrderByID)

	return r
}

// CreateOrder handles authoritative order creation.
func (h *Handler) CreateOrder(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req CreateOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	order, err := h.service.CreateOrder(r.Context(), userID, &req)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "CREATE_ORDER_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusCreated, order)
}

// ListOrders returns the authenticated customer's order history.
func (h *Handler) ListOrders(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	limit := 50
	if v := r.URL.Query().Get("limit"); v != "" {
		if parsed, err := strconv.Atoi(v); err == nil {
			limit = parsed
		}
	}
	offset := 0
	if v := r.URL.Query().Get("offset"); v != "" {
		if parsed, err := strconv.Atoi(v); err == nil {
			offset = parsed
		}
	}

	orders, err := h.service.ListOrders(r.Context(), userID, r.URL.Query().Get("order_type"), limit, offset)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "LIST_ORDERS_FAILED", "Failed to fetch orders", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, orders)
}

// CancelOrder handles pending order cancellation.
func (h *Handler) CancelOrder(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	orderID := chi.URLParam(r, "id")
	if orderID == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Order ID required", "")
		return
	}

	if err := h.service.CancelOrder(r.Context(), orderID, userID); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "CANCEL_ORDER_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, map[string]string{
		"message":  "Order successfully cancelled",
		"order_id": orderID,
	})
}

// TransitionOrder applies a role-authorized status transition.
func (h *Handler) TransitionOrder(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	orderID := chi.URLParam(r, "id")
	if orderID == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Order ID required", "")
		return
	}

	var req TransitionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	order, err := h.service.TransitionOrder(r.Context(), userID, orderID, req.Status)
	if err != nil {
		switch {
		case errors.Is(err, platform.ErrNotFound):
			platform.RespondError(w, http.StatusNotFound, "ORDER_NOT_FOUND", "Order not found", "")
		case errors.Is(err, platform.ErrForbidden):
			platform.RespondError(w, http.StatusForbidden, "FORBIDDEN", err.Error(), "")
		case errors.Is(err, platform.ErrConflict):
			platform.RespondError(w, http.StatusConflict, "INVALID_TRANSITION", err.Error(), "")
		default:
			platform.RespondError(w, http.StatusInternalServerError, "TRANSITION_FAILED", err.Error(), "")
		}
		return
	}

	platform.RespondJSON(w, http.StatusOK, order)
}

// GetOrderByID returns a single order (visibility enforced in service).
func (h *Handler) GetOrderByID(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	orderID := chi.URLParam(r, "id")
	if orderID == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Order ID required", "")
		return
	}

	order, err := h.service.GetOrderAuthorized(r.Context(), userID, orderID)
	if err != nil {
		if errors.Is(err, platform.ErrNotFound) {
			platform.RespondError(w, http.StatusNotFound, "ORDER_NOT_FOUND", "Order not found", "")
			return
		}
		if errors.Is(err, platform.ErrForbidden) {
			platform.RespondError(w, http.StatusForbidden, "FORBIDDEN", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ORDER_FAILED", "Failed to fetch order", "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, order)
}
