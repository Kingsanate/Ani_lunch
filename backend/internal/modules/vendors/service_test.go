package vendors

import (
	"context"
	"errors"
	"testing"

	"animeat/backend/internal/platform"
)

func TestNilDBAccess(t *testing.T) {
	s := NewService(nil)

	if _, err := s.GetProfile(context.Background(), "vendor-1"); !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}

	_, err := s.UpdateProfile(context.Background(), "vendor-1", &UpdateVendorRequest{})
	if !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}

	if _, err := s.ListOrders(context.Background(), "vendor-1"); !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}

	if _, err := s.GetStats(context.Background(), "vendor-1"); !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}
}