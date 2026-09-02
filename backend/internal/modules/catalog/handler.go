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
	r.Get("/daily_deals", h.GetDailyDeals)
	r.Get("/menus", h.GetMenus)
	r.Get("/meal_products", h.GetMealProducts)
	r.Get("/app_settings", h.GetAppSettings)

	return r
}

// GetMealProducts handles lunch thalis and meals.
func (h *Handler) GetMealProducts(w http.ResponseWriter, r *http.Request) {
	products, err := h.service.GetMealProducts(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_MEALS_FAILED", err.Error(), "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, products)
}

// GetAppSettings handles global app configuration.
func (h *Handler) GetAppSettings(w http.ResponseWriter, r *http.Request) {
	settings, err := h.service.GetAppSettings(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_SETTINGS_FAILED", err.Error(), "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, settings)
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
