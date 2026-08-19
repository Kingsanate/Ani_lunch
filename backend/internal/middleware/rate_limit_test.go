package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestRateLimiter_InMemoryLimit(t *testing.T) {
	limiter := NewRateLimiter(nil) // Uses in-memory fallback
	middleware := limiter.Limit(3, 1*time.Minute)

	handler := middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	// Requests 1, 2, 3 should be allowed
	for i := 1; i <= 3; i++ {
		req := httptest.NewRequest(http.MethodGet, "/test", nil)
		req.RemoteAddr = "192.168.1.100:1234"
		rec := httptest.NewRecorder()

		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("request %d expected status 200, got %d", i, rec.Code)
		}
	}

	// Request 4 should be rejected with 429 Too Many Requests
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	req.RemoteAddr = "192.168.1.100:1234"
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusTooManyRequests {
		t.Errorf("request 4 expected status 429, got %d", rec.Code)
	}

	if rec.Header().Get("Retry-After") == "" {
		t.Errorf("expected Retry-After header to be set")
	}
}
