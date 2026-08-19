package platform

import (
	"encoding/json"
	"net/http"
)

// StandardResponse wraps all API outputs in a unified JSON envelope.
type StandardResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *APIError   `json:"error,omitempty"`
	Meta    interface{} `json:"meta,omitempty"`
}

// APIError represents structured error detail.
type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Detail  string `json:"detail,omitempty"`
}

// RespondJSON writes a JSON response with status code.
func RespondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(StandardResponse{
		Success: status >= 200 && status < 300,
		Data:    data,
	})
}

// RespondError writes a standardized error JSON response.
func RespondError(w http.ResponseWriter, status int, code, message, detail string) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(StandardResponse{
		Success: false,
		Error: &APIError{
			Code:    code,
			Message: message,
			Detail:  detail,
		},
	})
}
