package health

import (
	"context"
	"net/http"
	"time"

	"animeat/backend/internal/database"
	"animeat/backend/internal/platform"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	db *database.Postgres
}

func NewHandler(db *database.Postgres) *Handler {
	return &Handler{db: db}
}

func (h *Handler) Routes() chi.Router {
	r := chi.NewRouter()
	r.Get("/live", h.Liveness)
	r.Get("/ready", h.Readiness)
	return r
}

// Liveness returns 200 OK if the process is running.
func (h *Handler) Liveness(w http.ResponseWriter, r *http.Request) {
	platform.RespondJSON(w, http.StatusOK, map[string]interface{}{
		"status":    "UP",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

// Readiness verifies database and external connectivity.
func (h *Handler) Readiness(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	dbStatus := "UP"
	if h.db != nil {
		if err := h.db.Ping(ctx); err != nil {
			dbStatus = "DOWN"
			platform.RespondError(w, http.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "Database connection unhealthy", err.Error())
			return
		}
	} else {
		dbStatus = "NOT_CONFIGURED"
	}

	platform.RespondJSON(w, http.StatusOK, map[string]interface{}{
		"status":    "READY",
		"database":  dbStatus,
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}
