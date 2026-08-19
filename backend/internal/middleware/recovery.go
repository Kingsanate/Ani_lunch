package middleware

import (
	"fmt"
	"log/slog"
	"net/http"
	"runtime/debug"

	"animeat/backend/internal/platform"
)

// Recovery handles panics cleanly and prevents server crashes.
func Recovery(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rvr := recover(); rvr != nil {
				reqID := GetRequestID(r.Context())
				stack := string(debug.Stack())

				slog.Error("panic_recovered",
					"request_id", reqID,
					"error", fmt.Sprintf("%v", rvr),
					"stack", stack,
				)

				platform.RespondError(w, http.StatusInternalServerError, "INTERNAL_PANIC", "An unexpected error occurred", "")
			}
		}()
		next.ServeHTTP(w, r)
	})
}
