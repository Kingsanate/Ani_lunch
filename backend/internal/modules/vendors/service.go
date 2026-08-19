package vendors

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"animeat/backend/internal/database"
	"animeat/backend/internal/platform"
	"github.com/jackc/pgx/v5"
)

type Service struct {
	db *database.Postgres
}

func NewService(db *database.Postgres) *Service {
	return &Service{db: db}
}

// GetProfile returns the vendor's own profile.
func (s *Service) GetProfile(ctx context.Context, vendorID string) (*Vendor, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var v Vendor
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id, name, address, phone, location_lat, location_lng, is_open, created_at, updated_at
		FROM vendors WHERE id = $1
	`, vendorID).Scan(
		&v.ID, &v.Name, &v.Address, &v.Phone,
		&v.LocationLat, &v.LocationLng, &v.IsOpen, &v.CreatedAt, &v.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, platform.ErrNotFound
		}
		return nil, fmt.Errorf("failed to fetch vendor profile: %w", err)
	}

	return &v, nil
}

// UpdateProfile updates editable vendor fields. Coordinates and is_open accept
// explicit nulls/false so partial updates never corrupt existing data.
func (s *Service) UpdateProfile(ctx context.Context, vendorID string, req *UpdateVendorRequest) (*Vendor, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	_, err := s.db.Pool.Exec(ctx, `
		UPDATE vendors SET
			name         = COALESCE(NULLIF($2, ''), name),
			address      = COALESCE(NULLIF($3, ''), address),
			phone        = COALESCE(NULLIF($4, ''), phone),
			location_lat = CASE WHEN $5 IS NULL THEN location_lat ELSE $5 END,
			location_lng = CASE WHEN $6 IS NULL THEN location_lng ELSE $6 END,
			is_open      = COALESCE($7, is_open),
			updated_at   = NOW()
		WHERE id = $1
	`, vendorID, valueOrEmpty(req.Name), valueOrEmpty(req.Address), valueOrEmpty(req.Phone),
		req.LocationLat, req.LocationLng, req.IsOpen)
	if err != nil {
		return nil, fmt.Errorf("failed to update vendor profile: %w", err)
	}

	return s.GetProfile(ctx, vendorID)
}

// ListOrders returns active kitchen orders for the vendor's store.
// Read-only and stale-tolerant: served from the read replica when configured.
// Transitions re-validate state on the primary, so a stale queue listing can
// never advance an order incorrectly.
func (s *Service) ListOrders(ctx context.Context, vendorID string) ([]VendorOrder, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	rows, err := s.db.Reader().Query(ctx, `
		SELECT o.id, o.user_id, o.status, o.items, o.subtotal_paise, o.delivery_fee_paise, o.discount_paise,
		       o.total_amount_paise, o.payment_method, o.payment_status, o.special_notes,
		       o.rider_id, o.order_time,
		       COALESCE(u.name, ''),
		       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip))
		FROM orders o
		LEFT JOIN users u ON u.id = o.user_id
		WHERE o.vendor_id = $1
		  AND o.status IN ('pending', 'confirmed', 'preparing', 'ready_for_pickup', 'accepted')
		ORDER BY o.order_time ASC
	`, vendorID)
	if err != nil {
		return nil, fmt.Errorf("failed to query vendor orders: %w", err)
	}
	defer rows.Close()

	var orders []VendorOrder
	for rows.Next() {
		var o VendorOrder
		var itemsJSON []byte
		if err := rows.Scan(
			&o.ID, &o.UserID, &o.Status, &itemsJSON,
			&o.Subtotal, &o.DeliveryFee, &o.Discount, &o.TotalAmount,
			&o.PaymentMethod, &o.PaymentStatus, &o.SpecialNotes,
			&o.RiderID, &o.OrderTime, &o.CustomerName, &o.Address,
		); err != nil {
			return nil, fmt.Errorf("failed to scan vendor order: %w", err)
		}
		if len(itemsJSON) > 0 {
			_ = json.Unmarshal(itemsJSON, &o.Items)
		}
		orders = append(orders, o)
	}

	return orders, rows.Err()
}

// GetStats returns the vendor's daily operational metrics.
// Read-only and stale-tolerant: served from the read replica when configured.
func (s *Service) GetStats(ctx context.Context, vendorID string) (*VendorStats, error) {
	if s.db == nil || s.db.Reader() == nil {
		return nil, platform.ErrInternal
	}

	startOfDay := time.Now().UTC().Truncate(24 * time.Hour)

	stats := &VendorStats{}
	err := s.db.Reader().QueryRow(ctx, `
		SELECT
			COUNT(*) FILTER (WHERE order_time >= $2),
			COALESCE(SUM(total_amount_paise) FILTER (WHERE order_time >= $2 AND status IN ('delivered', 'completed')), 0),
			COUNT(*) FILTER (WHERE status = 'pending' OR status = 'confirmed'),
			COUNT(*) FILTER (WHERE status = 'preparing'),
			COUNT(*) FILTER (WHERE status = 'ready_for_pickup'),
			COUNT(*) FILTER (WHERE status IN ('delivered', 'completed') AND order_time >= $2)
		FROM orders WHERE vendor_id = $1
	`, vendorID, startOfDay).Scan(
		&stats.OrdersToday, &stats.RevenueToday,
		&stats.PendingCount, &stats.PreparingCount,
		&stats.ReadyCount, &stats.CompletedToday,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to compute vendor stats: %w", err)
	}

	return stats, nil
}

func valueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}