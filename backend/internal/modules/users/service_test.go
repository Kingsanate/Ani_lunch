package users

import (
	"context"
	"errors"
	"testing"

	"animeat/backend/internal/platform"
)

func TestNilDBAccess(t *testing.T) {
	s := NewService(nil)

	if _, err := s.GetProfile(context.Background(), "user-1"); !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}

	_, err := s.UpsertProfile(context.Background(), "user-1", "a@b.c", &UpdateProfileRequest{})
	if !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}
}

func TestValueOrEmpty(t *testing.T) {
	if got := valueOrEmpty(nil); got != "" {
		t.Fatalf("expected empty string, got %q", got)
	}
	val := "hello"
	if got := valueOrEmpty(&val); got != "hello" {
		t.Fatalf("expected hello, got %q", got)
	}
}