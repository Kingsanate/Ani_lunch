package middleware

import (
	"log/slog"
	"net/http"
	"time"
)

type responseWriterDelegator struct {
	http.ResponseWriter
	statusCode int
	bytesRead  int
}

func (rw *responseWriterDelegator) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

func (rw *responseWriterDelegator) Write(b []byte) (int, error) {
	if rw.statusCode == 0 {
		rw.statusCode = http.StatusOK
	}
	n, err := rw.ResponseWriter.Write(b)
	rw.bytesRead += n
	return n, err
}

// Logger produces structured JSON access logs for each HTTP request.
func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		delegator := &responseWriterDelegator{ResponseWriter: w}

		next.ServeHTTP(delegator, r)

		duration := time.Since(start)
		reqID := GetRequestID(r.Context())

		status := delegator.statusCode
		if status == 0 {
			status = http.StatusOK
		}

		slog.Info("http_request",
			"request_id", reqID,
			"method", r.Method,
			"path", r.URL.Path,
			"status", status,
			"duration_ms", duration.Milliseconds(),
			"bytes", delegator.bytesRead,
			"ip", r.RemoteAddr,
			"user_agent", r.UserAgent(),
		)
	})
}
