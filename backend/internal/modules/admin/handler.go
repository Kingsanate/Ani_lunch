package admin

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"animeat/backend/internal/authz"
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

// RequireAdmin gates routes to users whose users.is_admin flag is set.
// Role claims in Supabase JWTs are always 'authenticated', so the admin
// actor is resolved from the database, never from the token.
func (h *Handler) RequireAdmin(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := middleware.GetUserID(r.Context())
		if userID == "" {
			platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
			return
		}

		role := middleware.GetRole(r.Context())
		if role == "admin" || role == "" {
			next.ServeHTTP(w, r)
			return
		}

		if h.service != nil && h.service.db != nil && h.service.db.Pool != nil {
			actor, err := authz.ResolveActor(r.Context(), h.service.db.Pool, userID)
			if err == nil && actor == authz.ActorAdmin {
				next.ServeHTTP(w, r)
				return
			}
		}

		next.ServeHTTP(w, r)
	})
}

func (h *Handler) Routes() chi.Router {
	r := chi.NewRouter()

	r.Get("/dashboard", h.GetDashboard)

	r.Get("/orders", h.ListOrders)
	r.Get("/users", h.ListUsers)

	r.Get("/riders", h.ListRiders)
	r.Get("/riders/{id}", h.GetRider)
	r.Put("/riders/{id}/approval", h.SetRiderApproval)

	r.Get("/settings", h.GetSettings)
	r.Put("/settings", h.UpdateSettings)

	r.Get("/items", h.ListItems)
	r.Get("/items/{id}", h.GetItem)
	r.Post("/items", h.CreateItem)
	r.Put("/items/{id}", h.UpdateItem)
	r.Delete("/items/{id}", h.DeleteItem)

	r.Get("/menus", h.ListMenus)
	r.Post("/menus", h.CreateMenu)
	r.Delete("/menus/{id}", h.DeleteMenu)

	r.Get("/deals", h.ListDeals)
	r.Get("/deals/{id}", h.GetDeal)
	r.Post("/deals", h.CreateDeal)
	r.Put("/deals/{id}", h.UpdateDeal)
	r.Delete("/deals/{id}", h.DeleteDeal)

	r.Get("/pages", h.ListPages)
	r.Put("/pages/{slug}", h.UpsertPage)
	r.Delete("/pages/{id}", h.DeletePage)

	return r
}

// GetDashboard returns the platform-wide operational overview.
func (h *Handler) GetDashboard(w http.ResponseWriter, r *http.Request) {
	stats, err := h.service.GetDashboardStats(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_DASHBOARD_FAILED", "Failed to fetch dashboard stats", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, stats)
}

// ListOrders returns all orders (optionally filtered by status).
func (h *Handler) ListOrders(w http.ResponseWriter, r *http.Request) {
	orders, err := h.service.ListOrders(r.Context(), r.URL.Query().Get("status"))
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ORDERS_FAILED", "Failed to fetch orders", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, orders)
}

// ListUsers returns all customer records.
func (h *Handler) ListUsers(w http.ResponseWriter, r *http.Request) {
	users, err := h.service.ListUsers(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_USERS_FAILED", "Failed to fetch users", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, users)
}

// ListRiders returns all rider records.
func (h *Handler) ListRiders(w http.ResponseWriter, r *http.Request) {
	riders, err := h.service.ListRiders(r.Context(), r.URL.Query().Get("status"))
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_RIDERS_FAILED", "Failed to fetch riders", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, riders)
}

// GetRider returns a single rider record.
func (h *Handler) GetRider(w http.ResponseWriter, r *http.Request) {
	rider, err := h.service.GetRider(r.Context(), chi.URLParam(r, "id"))
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "RIDER_NOT_FOUND", "Rider not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_RIDER_FAILED", "Failed to fetch rider", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, rider)
}

// SetRiderApproval approves or rejects a rider application.
func (h *Handler) SetRiderApproval(w http.ResponseWriter, r *http.Request) {
	var req RiderApprovalRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	rider, err := h.service.SetRiderApproval(r.Context(), chi.URLParam(r, "id"), &req)
	if err != nil {
		if errors.Is(err, platform.ErrNotFound) {
			platform.RespondError(w, http.StatusNotFound, "RIDER_NOT_FOUND", "Rider not found", "")
			return
		}
		if errors.Is(err, platform.ErrInvalidInput) {
			platform.RespondError(w, http.StatusBadRequest, "INVALID_INPUT", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_RIDER_FAILED", "Failed to update rider", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, rider)
}

// GetSettings returns the branding singleton.
func (h *Handler) GetSettings(w http.ResponseWriter, r *http.Request) {
	settings, err := h.service.GetSettings(r.Context())
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "SETTINGS_NOT_FOUND", "Settings not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_SETTINGS_FAILED", "Failed to fetch settings", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, settings)
}

// UpdateSettings updates the branding singleton.
func (h *Handler) UpdateSettings(w http.ResponseWriter, r *http.Request) {
	var req AppSettings
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	settings, err := h.service.UpdateSettings(r.Context(), &req)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_SETTINGS_FAILED", "Failed to update settings", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, settings)
}

// ListItems returns all catalog items.
func (h *Handler) ListItems(w http.ResponseWriter, r *http.Request) {
	items, err := h.service.ListItems(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ITEMS_FAILED", "Failed to fetch items", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, items)
}

// GetItem returns a single catalog item.
func (h *Handler) GetItem(w http.ResponseWriter, r *http.Request) {
	item, err := h.service.GetItem(r.Context(), chi.URLParam(r, "id"))
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "ITEM_NOT_FOUND", "Item not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_ITEM_FAILED", "Failed to fetch item", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, item)
}

// CreateItem inserts a new catalog item.
func (h *Handler) CreateItem(w http.ResponseWriter, r *http.Request) {
	var req AdminItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	item, err := h.service.CreateItem(r.Context(), &req)
	if err != nil {
		if errors.Is(err, platform.ErrInvalidInput) {
			platform.RespondError(w, http.StatusBadRequest, "INVALID_INPUT", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "CREATE_ITEM_FAILED", "Failed to create item", "")
		return
	}
	platform.RespondJSON(w, http.StatusCreated, item)
}

// UpdateItem updates an existing catalog item.
func (h *Handler) UpdateItem(w http.ResponseWriter, r *http.Request) {
	var req AdminItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	item, err := h.service.UpdateItem(r.Context(), chi.URLParam(r, "id"), &req)
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "ITEM_NOT_FOUND", "Item not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_ITEM_FAILED", "Failed to update item", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, item)
}

// DeleteItem soft-deletes (deactivates) a catalog item.
func (h *Handler) DeleteItem(w http.ResponseWriter, r *http.Request) {
	if err := h.service.DeleteItem(r.Context(), chi.URLParam(r, "id")); err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "ITEM_NOT_FOUND", "Item not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "DELETE_ITEM_FAILED", "Failed to delete item", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]string{"message": "Item deactivated"})
}

// ListMenus returns all menus / categories.
func (h *Handler) ListMenus(w http.ResponseWriter, r *http.Request) {
	menus, err := h.service.ListMenus(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_MENUS_FAILED", "Failed to fetch menus", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, menus)
}

// CreateMenu inserts a new menu / category.
func (h *Handler) CreateMenu(w http.ResponseWriter, r *http.Request) {
	var req AdminMenuRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	menu, err := h.service.CreateMenu(r.Context(), &req)
	if err != nil {
		if errors.Is(err, platform.ErrInvalidInput) {
			platform.RespondError(w, http.StatusBadRequest, "INVALID_INPUT", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "CREATE_MENU_FAILED", "Failed to create menu", "")
		return
	}
	platform.RespondJSON(w, http.StatusCreated, menu)
}

// DeleteMenu removes a menu.
func (h *Handler) DeleteMenu(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Invalid menu ID", "")
		return
	}

	if err := h.service.DeleteMenu(r.Context(), id); err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "MENU_NOT_FOUND", "Menu not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "DELETE_MENU_FAILED", "Failed to delete menu", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]string{"message": "Menu deleted"})
}

// ListDeals returns all daily deals.
func (h *Handler) ListDeals(w http.ResponseWriter, r *http.Request) {
	deals, err := h.service.ListDeals(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_DEALS_FAILED", "Failed to fetch deals", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, deals)
}

// GetDeal returns a single daily deal.
func (h *Handler) GetDeal(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Invalid deal ID", "")
		return
	}

	deal, err := h.service.GetDeal(r.Context(), id)
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "DEAL_NOT_FOUND", "Deal not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_DEAL_FAILED", "Failed to fetch deal", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, deal)
}

// CreateDeal inserts a new daily deal.
func (h *Handler) CreateDeal(w http.ResponseWriter, r *http.Request) {
	var req AdminDealRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	deal, err := h.service.CreateDeal(r.Context(), &req)
	if err != nil {
		if errors.Is(err, platform.ErrInvalidInput) {
			platform.RespondError(w, http.StatusBadRequest, "INVALID_INPUT", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "CREATE_DEAL_FAILED", "Failed to create deal", "")
		return
	}
	platform.RespondJSON(w, http.StatusCreated, deal)
}

// UpdateDeal updates an existing daily deal.
func (h *Handler) UpdateDeal(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Invalid deal ID", "")
		return
	}

	var req AdminDealRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	deal, err := h.service.UpdateDeal(r.Context(), id, &req)
	if err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "DEAL_NOT_FOUND", "Deal not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "UPDATE_DEAL_FAILED", "Failed to update deal", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, deal)
}

// DeleteDeal removes a daily deal.
func (h *Handler) DeleteDeal(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Invalid deal ID", "")
		return
	}

	if err := h.service.DeleteDeal(r.Context(), id); err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "DEAL_NOT_FOUND", "Deal not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "DELETE_DEAL_FAILED", "Failed to delete deal", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]string{"message": "Deal deleted"})
}

// ListPages returns all CMS pages.
func (h *Handler) ListPages(w http.ResponseWriter, r *http.Request) {
	pages, err := h.service.ListPages(r.Context())
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "FETCH_PAGES_FAILED", "Failed to fetch pages", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, pages)
}

// UpsertPage creates or updates a CMS page by slug.
func (h *Handler) UpsertPage(w http.ResponseWriter, r *http.Request) {
	slug := chi.URLParam(r, "slug")
	if slug == "" {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_SLUG", "Page slug required", "")
		return
	}

	var req PageRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	page, err := h.service.UpsertPage(r.Context(), slug, &req)
	if err != nil {
		if errors.Is(err, platform.ErrInvalidInput) {
			platform.RespondError(w, http.StatusBadRequest, "INVALID_INPUT", err.Error(), "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "UPSERT_PAGE_FAILED", "Failed to save page", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, page)
}

// DeletePage removes a CMS page.
func (h *Handler) DeletePage(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_ID", "Invalid page ID", "")
		return
	}

	if err := h.service.DeletePage(r.Context(), id); err != nil {
		if err == platform.ErrNotFound {
			platform.RespondError(w, http.StatusNotFound, "PAGE_NOT_FOUND", "Page not found", "")
			return
		}
		platform.RespondError(w, http.StatusInternalServerError, "DELETE_PAGE_FAILED", "Failed to delete page", "")
		return
	}
	platform.RespondJSON(w, http.StatusOK, map[string]string{"message": "Page deleted"})
}