package media

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"animeat/backend/internal/config"
	"animeat/backend/internal/middleware"
	"animeat/backend/internal/storage"
)

func TestMediaUploadURL_Unauthorized(t *testing.T) {
	h := NewHandler(nil, &config.Config{})

	req := httptest.NewRequest(http.MethodPost, "/api/v1/media/upload-url", bytes.NewBufferString(`{}`))
	rec := httptest.NewRecorder()

	h.PresignUpload(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized, got %d", rec.Code)
	}
}

func TestMediaUploadURL_Unconfigured(t *testing.T) {
	h := NewHandler(nil, &config.Config{})

	req := httptest.NewRequest(http.MethodPost, "/api/v1/media/upload-url", bytes.NewBufferString(`{}`))
	ctx := context.WithValue(req.Context(), middleware.UserIDContextKey, "user-123")
	req = req.WithContext(ctx)
	rec := httptest.NewRecorder()

	h.PresignUpload(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected 503 Service Unavailable, got %d", rec.Code)
	}
}

func TestMediaUploadURL_SuccessWithR2(t *testing.T) {
	ctx := context.Background()
	r2, err := storage.NewR2Client(ctx, storage.Config{
		AccountID:       "6aa8293912a4d03e7381bc2b5edf8d77",
		AccessKeyID:     "6aa8293912a4d03e7381bc2b5edf8d77",
		SecretAccessKey: "0167603b2773faf511bbc8fd3e1e1c2ca6eca91fdedf8808f1da60dbc3e7ceb2",
		Bucket:          "animeat-media",
		PublicBase:      "https://cdn.animeat.app",
	})
	if err != nil {
		t.Fatalf("failed to initialize R2 client: %v", err)
	}

	h := NewHandler(r2, &config.Config{})

	body := `{"content_type":"image/webp","kind":"item","ext":"webp"}`
	req := httptest.NewRequest(http.MethodPost, "/api/v1/media/upload-url", bytes.NewBufferString(body))
	reqCtx := context.WithValue(req.Context(), middleware.UserIDContextKey, "user-123")
	req = req.WithContext(reqCtx)
	rec := httptest.NewRecorder()

	h.PresignUpload(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d (body: %s)", rec.Code, rec.Body.String())
	}

	var resp struct {
		Success bool              `json:"success"`
		Data    map[string]string `json:"data"`
	}
	if err := json.NewDecoder(rec.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	data := resp.Data
	if !strings.HasPrefix(data["key"], "items/") || !strings.HasSuffix(data["key"], ".webp") {
		t.Errorf("unexpected key format: %s", data["key"])
	}

	if !strings.Contains(data["upload_url"], "r2.cloudflarestorage.com") {
		t.Errorf("expected presigned upload URL to target R2, got: %s", data["upload_url"])
	}

	if !strings.HasPrefix(data["public_url"], "https://cdn.animeat.app/items/") {
		t.Errorf("expected public CDN URL format, got: %s", data["public_url"])
	}
}

func TestBuildKey(t *testing.T) {
	kinds := map[string]string{
		"avatar": "avatars/u-1/",
		"item":   "items/",
		"vendor": "vendors/u-1/",
		"video":  "videos/",
		"other":  "misc/u-1/",
	}

	for kind, prefix := range kinds {
		k := buildKey(kind, "u-1", "jpg")
		if !strings.HasPrefix(k, prefix) || !strings.HasSuffix(k, ".jpg") {
			t.Errorf("kind %s produced key %s, want prefix %s", kind, k, prefix)
		}
	}
}
