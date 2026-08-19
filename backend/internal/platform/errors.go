package platform

import "errors"

var (
	ErrNotFound          = errors.New("resource not found")
	ErrUnauthorized      = errors.New("unauthorized")
	ErrForbidden         = errors.New("forbidden")
	ErrInvalidInput      = errors.New("invalid input")
	ErrConflict          = errors.New("resource conflict")
	ErrRateLimitExceeded = errors.New("rate limit exceeded")
	ErrInternal          = errors.New("internal server error")
)
