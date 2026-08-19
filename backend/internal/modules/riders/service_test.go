package riders

import (
	"context"
	"errors"
	"testing"

	"animeat/backend/internal/platform"
)

func TestUpdateLocationValidation(t *testing.T) {
	s := NewService(nil)

	tests := []struct {
		name      string
		loc       LocationUpdate
		wantError bool
	}{
		{name: "valid coordinates", loc: LocationUpdate{Latitude: 25.5941, Longitude: 85.1376}},
		{name: "latitude too low", loc: LocationUpdate{Latitude: -91, Longitude: 0}, wantError: true},
		{name: "latitude too high", loc: LocationUpdate{Latitude: 91, Longitude: 0}, wantError: true},
		{name: "longitude too low", loc: LocationUpdate{Latitude: 0, Longitude: -181}, wantError: true},
		{name: "longitude too high", loc: LocationUpdate{Latitude: 0, Longitude: 181}, wantError: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := s.UpdateLocation(context.Background(), "rider-1", tt.loc)
			if tt.wantError {
				if !errors.Is(err, platform.ErrInvalidInput) {
					t.Fatalf("expected ErrInvalidInput, got %v", err)
				}
				return
			}
			if err == nil {
				t.Fatal("expected database error (nil pool), got nil")
			}
		})
	}
}

func TestUpsertProfileNilDB(t *testing.T) {
	s := NewService(nil)
	_, err := s.UpsertProfile(context.Background(), "rider-1", &UpdateProfileRequest{})
	if !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}
}

func TestAcceptOrderNilDB(t *testing.T) {
	s := NewService(nil)
	_, err := s.AcceptOrder(context.Background(), "rider-1", "order-1")
	if !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}
}