package admin

import (
	"context"
	"errors"
	"testing"

	"animeat/backend/internal/platform"
)

func TestCreateItemValidation(t *testing.T) {
	s := NewService(nil, nil)

	tests := []struct {
		name string
		req  *AdminItemRequest
	}{
		{name: "missing title", req: &AdminItemRequest{Price: 1000}},
		{name: "zero price", req: &AdminItemRequest{ItemTitle: "Chicken 1kg"}},
		{name: "negative price", req: &AdminItemRequest{ItemTitle: "Chicken 1kg", Price: -100}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := s.CreateItem(context.Background(), tt.req)
			if !errors.Is(err, platform.ErrInvalidInput) {
				t.Fatalf("expected ErrInvalidInput, got %v", err)
			}
		})
	}
}

func TestCreateDealValidation(t *testing.T) {
	s := NewService(nil, nil)

	tests := []struct {
		name string
		req  *AdminDealRequest
	}{
		{name: "missing title", req: &AdminDealRequest{DealPrice: 1000}},
		{name: "zero deal price", req: &AdminDealRequest{Title: "Festive Deal"}},
		{name: "negative deal price", req: &AdminDealRequest{Title: "Festive Deal", DealPrice: -50}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := s.CreateDeal(context.Background(), tt.req)
			if !errors.Is(err, platform.ErrInvalidInput) {
				t.Fatalf("expected ErrInvalidInput, got %v", err)
			}
		})
	}
}

func TestCreateMenuValidation(t *testing.T) {
	s := NewService(nil, nil)
	_, err := s.CreateMenu(context.Background(), &AdminMenuRequest{})
	if !errors.Is(err, platform.ErrInvalidInput) {
		t.Fatalf("expected ErrInvalidInput, got %v", err)
	}
}

func TestUpsertPageValidation(t *testing.T) {
	s := NewService(nil, nil)
	_, err := s.UpsertPage(context.Background(), "terms", &PageRequest{})
	if !errors.Is(err, platform.ErrInvalidInput) {
		t.Fatalf("expected ErrInvalidInput, got %v", err)
	}
}

func TestSetRiderApprovalValidation(t *testing.T) {
	s := NewService(nil, nil)
	_, err := s.SetRiderApproval(context.Background(), "rider-1", &RiderApprovalRequest{ApprovalStatus: "maybe"})
	if !errors.Is(err, platform.ErrInvalidInput) {
		t.Fatalf("expected ErrInvalidInput, got %v", err)
	}
}

func TestNilDBAccess(t *testing.T) {
	s := NewService(nil, nil)

	if _, err := s.GetDashboardStats(context.Background()); !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}
	if _, err := s.GetSettings(context.Background()); !errors.Is(err, platform.ErrInternal) {
		t.Fatalf("expected ErrInternal, got %v", err)
	}
}