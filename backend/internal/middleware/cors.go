package middleware

import (
	"net/http"

	"github.com/go-chi/cors"
)

// CORS configures permissive yet safe cross-origin access for web and mobile clients.
func CORS() func(http.Handler) http.Handler {
	return cors.Handler(cors.Options{
		AllowOriginFunc: func(r *http.Request, origin string) bool {
			return true // Allow all web browser origins dynamically (Chrome, localhost ports, production domains)
		},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token", "X-Request-ID", "Origin"},
		ExposedHeaders:   []string{"Link", "X-Request-ID"},
		AllowCredentials: true,
		MaxAge:           300,
	})
}
