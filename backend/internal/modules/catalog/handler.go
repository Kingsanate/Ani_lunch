package catalog

import (
	"net/http"

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

	r.Get("/items", h.GetItems)
	r.Get("/deals", h.GetDailyDeals)
	r.Get("/menus", h.GetMenus)

	return r
}

// GetMenus handles menu / category listing.
func (h *Handler) GetMenus(w http.ResponseWriter, r *http.Request) {
	menus, err := h.service.GetMenus(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_MENUS_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, menus)
}

// GetItems handles catalog items list with category filtering.
func (h *Handler) GetItems(w http.ResponseWriter, r *http.Request) {
	category := r.URL.Query().Get("category")

	items, err := h.service.GetItems(r.Context(), category)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ITEMS_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, items)
}

// GetDailyDeals handles active daily promotional deals.
func (h *Handler) GetDailyDeals(w http.ResponseWriter, r *http.Request) {
	deals, err := h.service.GetDailyDeals(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_DEALS_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, deals)
}
