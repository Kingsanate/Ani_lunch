package media

import (
	"encoding/json"
	"net/http"

	"animeat/backend/internal/config"
	"animeat/backend/internal/middleware"
	"animeat/backend/internal/platform"
	"animeat/backend/internal/storage"
	"github.com/google/uuid"
)

type Handler struct {
	r2  *storage.R2Client
	cfg *config.Config
}

func NewHandler(r2 *storage.R2Client, cfg *config.Config) *Handler {
	return &Handler{r2: r2, cfg: cfg}
}

// Routes returns chi-style handlers for media upload URLs.
func (h *Handler) Routes() map[string]http.HandlerFunc {
	return map[string]http.HandlerFunc{
		"POST /api/v1/media/upload-url": h.PresignUpload,
	}
}

type uploadURLRequest struct {
	ContentType string `json:"content_type"`
	Kind        string `json:"kind"` // "avatar" | "item" | "vendor" | "video"
	Ext         string `json:"ext"`  // e.g. "jpg", "png", "mp4"
}

// PresignUpload issues a short-lived PUT presigned URL so the client uploads
// media directly to R2 (never through the Go API). Path is scoped by kind.
func (h *Handler) PresignUpload(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}
	if h.r2 == nil {
		platform.RespondError(w, http.StatusServiceUnavailable, "STORAGE_UNCONFIGURED", "Media storage is not configured", "")
		return
	}

	var req uploadURLRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse request", "")
		return
	}
	if req.ContentType == "" {
		req.ContentType = "application/octet-stream"
	}
	if req.Ext == "" {
		req.Ext = "bin"
	}

	key := buildKey(req.Kind, userID, req.Ext)
	url, err := h.r2.PresignUpload(r.Context(), key, req.ContentType, 0)
	if err != nil {
		platform.RespondError(w, http.StatusInternalServerError, "PRESIGN_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, map[string]string{
		"upload_url": url,
		"key":        key,
		"public_url": h.r2.PublicURL(key),
	})
}

func buildKey(kind, userID, ext string) string {
	id := uuid.NewString()
	switch kind {
	case "avatar":
		return "avatars/" + userID + "/" + id + "." + ext
	case "item":
		return "items/" + id + "." + ext
	case "vendor":
		return "vendors/" + userID + "/" + id + "." + ext
	case "video":
		return "videos/" + id + "." + ext
	default:
		return "misc/" + userID + "/" + id + "." + ext
	}
}
