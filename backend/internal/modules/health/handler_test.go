package health

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"animeat/backend/internal/platform"
)

func TestHealth_Liveness(t *testing.T) {
	handler := NewHandler(nil)
	req := httptest.NewRequest(http.MethodGet, "/health/live", nil)
	rec := httptest.NewRecorder()

	handler.Liveness(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	var res platform.StandardResponse
	if err := json.NewDecoder(rec.Body).Decode(&res); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if !res.Success {
		t.Errorf("expected success true, got %v", res.Success)
	}
}

func TestHealth_Readiness_NilDB(t *testing.T) {
	handler := NewHandler(nil)
	req := httptest.NewRequest(http.MethodGet, "/health/ready", nil)
	rec := httptest.NewRecorder()

	handler.Readiness(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}
}
