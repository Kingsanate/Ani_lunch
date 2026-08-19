package middleware

import (
	"net/http"

	"github.com/go-chi/cors"
)

// CORS configures permissive yet safe cross-origin access for web and mobile clients.
func CORS() func(http.Handler) http.Handler {
	return cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token", "X-Request-ID"},
		ExposedHeaders:   []string{"Link", "X-Request-ID"},
		AllowCredentials: true,
		MaxAge:           300,
	})
}
