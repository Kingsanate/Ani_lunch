package vendors

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"animeat/backend/internal/database"
	"animeat/backend/internal/platform"
)

type Service struct {
	db *database.Postgres
}

func NewService(db *database.Postgres) *Service {
	return &Service{db: db}
}

// GetProfile returns the vendor's own profile.
func (s *Service) GetProfile(ctx context.Context, vendorID string) (*Vendor, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	if s.db.Pool != nil {
		var v Vendor
		err := s.db.Pool.QueryRow(ctx, `
			SELECT id, name, address, phone, location_lat, location_lng, is_open, created_at, updated_at
			FROM vendors WHERE id = $1
		`, vendorID).Scan(
			&v.ID, &v.Name, &v.Address, &v.Phone,
			&v.LocationLat, &v.LocationLng, &v.IsOpen, &v.CreatedAt, &v.UpdatedAt,
		)
		if err == nil {
			return &v, nil
		}
	}

	return &Vendor{
		ID:        vendorID,
		Name:      "Main Kitchen",
		Address:   "Central Kitchen, Shillong",
		Phone:     "+91 9774164689",
		IsOpen:    true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}, nil
}

// UpdateProfile updates editable vendor fields. Coordinates and is_open accept
// explicit nulls/false so partial updates never corrupt existing data.
func (s *Service) UpdateProfile(ctx context.Context, vendorID string, req *UpdateVendorRequest) (*Vendor, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	if s.db.Pool != nil {
		_, _ = s.db.Pool.Exec(ctx, `
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
	}

	return s.GetProfile(ctx, vendorID)
}

// ListOrders returns active kitchen orders for the vendor's store.
func (s *Service) ListOrders(ctx context.Context, vendorID string) ([]VendorOrder, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	var orders []VendorOrder
	if s.db != nil && s.db.Reader() != nil {
		rows, err := s.db.Reader().Query(ctx, `
			SELECT o.id, o.user_id, o.status, o.items, o.subtotal_paise, o.delivery_fee_paise, o.discount_paise,
			       o.total_amount_paise, o.payment_method, o.payment_status, o.special_notes,
			       o.rider_id, o.order_time,
			       COALESCE(u.name, ''),
			       TRIM(CONCAT_WS(', ', o.delivery_street, o.delivery_city, o.delivery_zip))
			FROM orders o
			LEFT JOIN users u ON u.id = o.user_id
			WHERE (o.vendor_id = $1 OR o.vendor_id IS NULL OR $1 = '')
			  AND o.status IN ('pending', 'confirmed', 'preparing', 'ready_for_pickup', 'accepted')
			ORDER BY o.order_time ASC
		`, vendorID)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				var o VendorOrder
				var itemsJSON []byte
				if err := rows.Scan(
					&o.ID, &o.UserID, &o.Status, &itemsJSON,
					&o.Subtotal, &o.DeliveryFee, &o.Discount, &o.TotalAmount,
					&o.PaymentMethod, &o.PaymentStatus, &o.SpecialNotes,
					&o.RiderID, &o.OrderTime, &o.CustomerName, &o.Address,
				); err == nil {
					if len(itemsJSON) > 0 {
						_ = json.Unmarshal(itemsJSON, &o.Items)
					}
					orders = append(orders, o)
				}
			}
		}
	}

	// Merge/fallback from GlobalStore
	memOrders := platform.GlobalStore.List()
	existingIDs := make(map[string]bool)
	for _, o := range orders {
		existingIDs[o.ID] = true
	}
	for _, mo := range memOrders {
		if !existingIDs[mo.ID] {
			specialNotes := ""
			if mo.SpecialNotes != nil {
				specialNotes = *mo.SpecialNotes
			}
			vItems := make([]VendorItem, 0)
			for _, it := range mo.Items {
				if m, ok := it.(map[string]any); ok {
					name, _ := m["name"].(string)
					if name == "" {
						name = "Signature Lunch Thali"
					}
					qty := 1
					if q, ok := m["quantity"].(float64); ok {
						qty = int(q)
					} else if q, ok := m["quantity"].(int); ok {
						qty = q
					}
					var price int64 = 20000
					if p, ok := m["unit_price_paise"].(float64); ok && p > 0 {
						price = int64(p)
					} else if p, ok := m["unit_price_paise"].(int64); ok && p > 0 {
						price = p
					} else if p, ok := m["price"].(float64); ok && p > 0 {
						price = int64(p * 100)
					} else if p, ok := m["price"].(int); ok && p > 0 {
						price = int64(p * 100)
					}
					img, _ := m["image"].(string)
					if img == "" {
						img, _ = m["image_url"].(string)
					}
					if img == "" {
						lower := strings.ToLower(name)
						img = "assets/images/bento.png"
						if strings.Contains(lower, "mizo") {
							img = "assets/images/pork.png"
						} else if strings.Contains(lower, "naga") {
							img = "assets/images/chicken.png"
						} else if strings.Contains(lower, "khasi") {
							img = "assets/images/beef.png"
						}
					}
					vItems = append(vItems, VendorItem{
						ID:        fmt.Sprintf("%v", m["item_id"]),
						ItemID:    fmt.Sprintf("%v", m["item_id"]),
						Name:      name,
						Quantity:  qty,
						UnitPrice: platform.FromPaise(price),
						Subtotal:  platform.FromPaise(price * int64(qty)),
						Image:     img,
					})
				}
			}
			orders = append(orders, VendorOrder{
				ID:            mo.ID,
				UserID:        mo.UserID,
				Status:        mo.Status,
				Subtotal:      mo.Subtotal,
				DeliveryFee:   mo.DeliveryFee,
				Discount:      mo.Discount,
				TotalAmount:   mo.TotalAmount,
				PaymentMethod: mo.PaymentMethod,
				PaymentStatus: mo.PaymentStatus,
				SpecialNotes:  specialNotes,
				RiderID:       mo.RiderID,
				OrderTime:     mo.OrderTime,
				CustomerName:  mo.CustomerName,
				Address:       mo.DeliveryStreet,
				Items:         vItems,
			})
		}
	}

	return orders, nil
}

// GetStats returns the vendor's daily operational metrics.
func (s *Service) GetStats(ctx context.Context, vendorID string) (*VendorStats, error) {
	if s.db == nil {
		return nil, platform.ErrInternal
	}
	startOfDay := time.Now().UTC().Truncate(24 * time.Hour)
	stats := &VendorStats{}

	if s.db != nil && s.db.Reader() != nil {
		_ = s.db.Reader().QueryRow(ctx, `
			SELECT
				COUNT(*) FILTER (WHERE order_time >= $2),
				COALESCE(SUM(total_amount_paise) FILTER (WHERE order_time >= $2 AND status IN ('delivered', 'completed')), 0),
				COUNT(*) FILTER (WHERE status = 'pending' OR status = 'confirmed'),
				COUNT(*) FILTER (WHERE status = 'preparing'),
				COUNT(*) FILTER (WHERE status = 'ready_for_pickup'),
				COUNT(*) FILTER (WHERE status IN ('delivered', 'completed') AND order_time >= $2)
			FROM orders WHERE (vendor_id = $1 OR vendor_id IS NULL OR $1 = '')
		`, vendorID, startOfDay).Scan(
			&stats.OrdersToday, &stats.RevenueToday,
			&stats.PendingCount, &stats.PreparingCount,
			&stats.ReadyCount, &stats.CompletedToday,
		)
	}

	memOrders := platform.GlobalStore.List()
	if len(memOrders) > 0 {
		for _, mo := range memOrders {
			if mo.OrderTime.After(startOfDay) {
				stats.OrdersToday++
			}
			switch mo.Status {
			case "pending", "confirmed":
				stats.PendingCount++
			case "preparing":
				stats.PreparingCount++
			case "ready_for_pickup":
				stats.ReadyCount++
			case "delivered", "completed":
				if mo.OrderTime.After(startOfDay) {
					stats.CompletedToday++
					stats.RevenueToday = stats.RevenueToday.Add(mo.TotalAmount)
				}
			}
		}
	}

	return stats, nil
}

func valueOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}