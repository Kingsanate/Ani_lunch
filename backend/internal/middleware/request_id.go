package middleware

import (
	"context"
	"net/http"

	"github.com/google/uuid"
)

type contextKey string

const (
	RequestIDHeader             = "X-Request-ID"
	RequestIDKey     contextKey = "request_id"
)

// RequestID attaches a unique request ID to each incoming request context and response header.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reqID := r.Header.Get(RequestIDHeader)
		if reqID == "" {
			reqID = uuid.New().String()
		}

		w.Header().Set(RequestIDHeader, reqID)
		ctx := context.WithValue(r.Context(), RequestIDKey, reqID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// GetRequestID extracts the request ID from context.
func GetRequestID(ctx context.Context) string {
	if val, ok := ctx.Value(RequestIDKey).(string); ok {
		return val
	}
	return ""
}
