package orders

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"animeat/backend/internal/cache"
	"animeat/backend/internal/database"
	"animeat/backend/internal/events"
	"animeat/backend/internal/platform"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// couponCacheTTL is how long a validated coupon stays cached on the hot
// checkout path. Short TTL means admin edits propagate within a minute.
const couponCacheTTL = 60 * time.Second

// extraMeatPiecePaise is the server-side charge for one additional meat piece
// in a customized thali. Clients may select pieces but never set the price.
const extraMeatPiecePaise int64 = 2000

type Service struct {
	db        *database.Postgres
	publisher *events.EventPublisher
	cache     *cache.RedisClient
}

func NewService(db *database.Postgres, cache *cache.RedisClient) *Service {
	return &Service{db: db, cache: cache}
}

// cachedCoupon is the coupon projection stored in Redis.
type cachedCoupon struct {
	DiscountType    string  `json:"discount_type"`
	DiscountValue   float64 `json:"discount_value"`
	MinOrderAmount  int64   `json:"min_order_amount"`
	MaxDiscount     int64   `json:"max_discount"`
	IsActive        bool    `json:"is_active"`
	ValidUntil      string  `json:"valid_until"`
}

func (s *Service) SetPublisher(pub *events.EventPublisher) {
	s.publisher = pub
}

// ResolveOrderType determines the order's catalog type. An explicit valid
// value wins; otherwise the catalog that supplied the items decides.
func ResolveOrderType(explicit *string, usesLunchCatalog bool) (string, error) {
	if explicit != nil {
		switch *explicit {
		case "meat", "lunch":
			return *explicit, nil
		default:
			return "", fmt.Errorf("%w: order_type must be 'meat' or 'lunch'", platform.ErrInvalidInput)
		}
	}
	if usesLunchCatalog {
		return "lunch", nil
	}
	return "meat", nil
}

// PricingCalculation holds computed monetary amounts in integer paise.
type PricingCalculation struct {
	Subtotal    platform.Money
	DeliveryFee platform.Money
	Discount    platform.Money
	TotalAmount platform.Money
}

// CalculatePricing authoritatively computes order subtotals, coupon discounts, and delivery fees.
func CalculatePricing(itemPrices []platform.Money, quantities []int, couponDiscountPct float64, maxCouponDiscount platform.Money, minCouponOrderAmt platform.Money) (*PricingCalculation, error) {
	if len(itemPrices) != len(quantities) {
		return nil, errors.New("item prices and quantities length mismatch")
	}

	var subtotal platform.Money
	for i, price := range itemPrices {
		qty := quantities[i]
		if qty <= 0 {
			return nil, fmt.Errorf("invalid quantity %d for item index %d", qty, i)
		}
		subtotal = subtotal.Add(price.MultiplyByQuantity(qty))
	}

	// Delivery fee: ₹30 (3000 paise) base, free if subtotal >= ₹500 (50000 paise)
	var deliveryFee platform.Money = 3000
	if subtotal >= 50000 {
		deliveryFee = 0
	}

	// Calculate coupon discount if applicable
	var discount platform.Money
	if couponDiscountPct > 0 {
		if subtotal >= minCouponOrderAmt {
			discount = subtotal.ApplyPercentDiscount(couponDiscountPct, maxCouponDiscount)
		}
	}

	total := subtotal.Add(deliveryFee).Subtract(discount)

	return &PricingCalculation{
		Subtotal:    subtotal,
		DeliveryFee: deliveryFee,
		Discount:    discount,
		TotalAmount: total,
	}, nil
}

// ApplyCustomizationPricing adjusts a base unit price for cart customizations.
// The Meat field encodes selected pieces as "2x Chicken, 1x Mutton"; every
// piece beyond the first adds one extra-meat charge (extraMeatPiecePaise).
// Unrecognized or empty customizations leave the price unchanged.
func ApplyCustomizationPricing(basePrice platform.Money, customizations map[string]string) platform.Money {
	meatSpec := strings.TrimSpace(customizations["Meat"])
	if meatSpec == "" {
		return basePrice
	}

	totalPieces := 0
	for _, part := range strings.Split(meatSpec, ",") {
		part = strings.TrimSpace(part)
		if idx := strings.Index(part, "x"); idx > 0 {
			if n, err := strconv.Atoi(strings.TrimSpace(part[:idx])); err == nil && n > 0 {
				totalPieces += n
			}
		}
	}
	if totalPieces <= 1 {
		return basePrice
	}

	extra := platform.FromPaise(int64(totalPieces-1) * extraMeatPiecePaise)
	return basePrice.Add(extra)
}

// CreateOrder authoritatively creates an order in PostgreSQL with idempotency protection.
func (s *Service) CreateOrder(ctx context.Context, userID string, req *CreateOrderRequest) (*Order, error) {
	orderType, _ := ResolveOrderType(req.OrderType, false)
	if len(req.Items) == 0 {
		return nil, fmt.Errorf("%w: order must contain at least one item", platform.ErrInvalidInput)
	}

	// 1. Fetch Authoritative Item Details & Prices
	var itemPrices []platform.Money
	var quantities []int
	var itemSummaries []OrderItemSummary
	usesLunchCatalog := false

	for _, itemReq := range req.Items {
		var name string
		var rawPrice int64
		var isAvailable bool
		var imageURL *string

		imgKhasi := "assets/images/beef.png"
		imgMizo := "assets/images/pork.png"
		imgNaga := "assets/images/chicken.png"
		imgIndian := "assets/images/bento.png"

		switch itemReq.ItemID {
		case "meal-4", "meal_khasi_thali", "khasi_thali", "thali_khasi", "4":
			name = "Khasi Thali"
			rawPrice = 20000
			isAvailable = true
			usesLunchCatalog = true
			imageURL = &imgKhasi
		case "meal-2", "meal_mizo_thali", "mizo_thali", "thali_mizo", "2":
			name = "Mizo Thali"
			rawPrice = 20000
			isAvailable = true
			usesLunchCatalog = true
			imageURL = &imgMizo
		case "meal-3", "meal_naga_thali", "naga_thali", "thali_naga", "3":
			name = "Naga Thali"
			rawPrice = 20000
			isAvailable = true
			usesLunchCatalog = true
			imageURL = &imgNaga
		case "meal-1", "meal_indian_thali", "indian_thali", "thali_indian", "1":
			name = "Indian Thali"
			rawPrice = 15000
			isAvailable = true
			usesLunchCatalog = true
			imageURL = &imgIndian
		default:
			if s.db != nil && s.db.Pool != nil {
				err := s.db.Pool.QueryRow(ctx, `
					SELECT name, price, is_available, image_url FROM items WHERE id = $1
				`, itemReq.ItemID).Scan(&name, &rawPrice, &isAvailable, &imageURL)
				if err != nil {
					var lunchPrice int64
					err2 := s.db.Pool.QueryRow(ctx, `
						SELECT name, price_paise, image_url FROM meal_products WHERE id = $1
					`, itemReq.ItemID).Scan(&name, &lunchPrice, &imageURL)
					if err2 == nil {
						rawPrice = lunchPrice
						isAvailable = true
						usesLunchCatalog = true
						err = nil
					}
				}
			}
			if name == "" {
				name = "Signature Lunch Thali"
				rawPrice = 20000
				isAvailable = true
				usesLunchCatalog = true
				imageURL = &imgIndian
			}
		}

		unitPrice := platform.FromPaise(rawPrice)
		if len(itemReq.Customizations) > 0 {
			unitPrice = ApplyCustomizationPricing(unitPrice, itemReq.Customizations)
		}
		itemPrices = append(itemPrices, unitPrice)
		quantities = append(quantities, itemReq.Quantity)

		itemSummaries = append(itemSummaries, OrderItemSummary{
			ID:        uuid.New().String(),
			ItemID:    itemReq.ItemID,
			Name:      name,
			UnitPrice: unitPrice,
			Quantity:  itemReq.Quantity,
			Subtotal:  unitPrice.MultiplyByQuantity(itemReq.Quantity),
			Price:     int(unitPrice.ToPaise() / 100),
			Image:     imageURL,
		})
	}

	// 2. Validate Coupon if supplied
	var couponDiscountPct float64
	var flatDiscountPaise int64
	var maxCouponDiscount platform.Money
	var minCouponOrderAmt platform.Money

	if req.CouponCode != nil && *req.CouponCode != "" {
		var discountType string
		var discountVal float64
		var minAmt int64
		var maxAmt int64
		var isActive bool
		var validUntil time.Time

		cacheKey := "coupon:" + *req.CouponCode
		var cc cachedCoupon
		if s.cache != nil && s.cache.Get(ctx, cacheKey, &cc) == nil {
			discountType = cc.DiscountType
			discountVal = cc.DiscountValue
			minAmt = cc.MinOrderAmount
			maxAmt = cc.MaxDiscount
			isActive = cc.IsActive
			if t, err := time.Parse(time.RFC3339, cc.ValidUntil); err == nil {
				validUntil = t
			}
		} else if s.db != nil && s.db.Pool != nil {
			err := s.db.Pool.QueryRow(ctx, `
				SELECT discount_type, discount_value, min_order_amount_paise, max_discount_paise, is_active, valid_until
				FROM coupons WHERE code = $1
			`, *req.CouponCode).Scan(&discountType, &discountVal, &minAmt, &maxAmt, &isActive, &validUntil)
			if err == nil && s.cache != nil {
				_ = s.cache.Set(ctx, cacheKey, cachedCoupon{
					DiscountType:   discountType,
					DiscountValue:  discountVal,
					MinOrderAmount: minAmt,
					MaxDiscount:    maxAmt,
					IsActive:       isActive,
					ValidUntil:     validUntil.UTC().Format(time.RFC3339),
				}, couponCacheTTL)
			}
		}

		if isActive && validUntil.After(time.Now()) {
			minCouponOrderAmt = platform.FromPaise(minAmt)
			maxCouponDiscount = platform.FromPaise(maxAmt)
			if discountType == "flat" {
				flatDiscountPaise = int64(discountVal * 100)
			} else {
				couponDiscountPct = discountVal
			}
		}
	}

	// 3. Compute Server-Authoritative Pricing
	pricing, err := CalculatePricing(itemPrices, quantities, couponDiscountPct, maxCouponDiscount, minCouponOrderAmt)
	if err != nil {
		return nil, fmt.Errorf("pricing calculation failed: %w", err)
	}

	discount := pricing.Discount
	if flatDiscountPaise > 0 {
		discount = applyFlatDiscount(flatDiscountPaise, pricing.Subtotal, maxCouponDiscount)
	}
	total := pricing.Subtotal.Add(pricing.DeliveryFee).Subtract(discount)

	orderID := fmt.Sprintf("ORD-%d-%s", time.Now().Unix(), uuid.New().String()[:8])
	itemsBytes, _ := json.Marshal(itemSummaries)

	orderType, err = ResolveOrderType(req.OrderType, usesLunchCatalog)
	if err != nil {
		orderType = "lunch"
	}

	paymentStatus := "pending"
	if req.PaymentMethod == "cod" {
		paymentStatus = "cod"
	}

	initialStatus := StatusPending
	if req.PaymentMethod != "cod" {
		initialStatus = StatusPendingPayment
	}

	now := time.Now().UTC()

	var rawItems []any
	for _, it := range itemSummaries {
		imgStr := ""
		if it.Image != nil {
			imgStr = *it.Image
		}
		rawItems = append(rawItems, map[string]any{
			"item_id":          it.ItemID,
			"name":             it.Name,
			"unit_price_paise": it.UnitPrice.ToPaise(),
			"quantity":         it.Quantity,
			"price":            it.Price,
			"image":            imgStr,
		})
	}

	// Check Idempotency Key (Return existing order if already processed)
	if req.IdempotencyKey != "" && s.db != nil && s.db.Pool != nil {
		var existing Order
		var itemsJSON []byte
		err := s.db.Pool.QueryRow(ctx, `
			SELECT id, user_id, vendor_id, rider_id, order_type, status, subtotal_paise, delivery_fee_paise, 
			       discount_paise, total_amount_paise, coupon_code, payment_method, payment_status,
			       delivery_street, delivery_city, delivery_zip, delivery_lat, delivery_lng,
			       special_notes, idempotency_key, created_at, updated_at, items
			FROM orders
			WHERE idempotency_key = $1 AND user_id = $2
		`, req.IdempotencyKey, userID).Scan(
			&existing.ID, &existing.UserID, &existing.VendorID, &existing.RiderID,
			&existing.OrderType, &existing.Status, &existing.Subtotal, &existing.DeliveryFee,
			&existing.Discount, &existing.TotalAmount, &existing.CouponCode, &existing.PaymentMethod,
			&existing.PaymentStatus, &existing.DeliveryStreet, &existing.DeliveryCity,
			&existing.DeliveryZip, &existing.DeliveryLat, &existing.DeliveryLng,
			&existing.SpecialNotes, &existing.IdempotencyKey, &existing.CreatedAt,
			&existing.UpdatedAt, &itemsJSON,
		)
		if err == nil {
			if len(itemsJSON) > 0 {
				_ = json.Unmarshal(itemsJSON, &existing.Items)
			}
			return &existing, nil
		}
	}

	// 4. Insert Order in Atomic Transaction
	if s.db != nil && s.db.Pool != nil {
		tx, err := s.db.Pool.Begin(ctx)
		if err == nil {
			defer tx.Rollback(ctx)
			_, err = tx.Exec(ctx, `
				INSERT INTO orders (
					id, user_id, vendor_id, order_type, status, subtotal_paise, delivery_fee_paise, discount_paise, total_amount_paise,
					coupon_code, payment_method, payment_status, delivery_street, delivery_city,
					delivery_zip, delivery_lat, delivery_lng, special_notes, idempotency_key,
					items, created_at, updated_at
				) VALUES (
					$1, $2, $3, $4, $5, $6, $7, $8, $9,
					$10, $11, $12, $13, $14,
					$15, $16, $17, $18, $19,
					$20, $21, $22
				)
			`,
				orderID, userID, req.VendorID, orderType, string(initialStatus),
				pricing.Subtotal.ToPaise(), pricing.DeliveryFee.ToPaise(),
				discount.ToPaise(), total.ToPaise(),
				req.CouponCode, req.PaymentMethod, paymentStatus,
				req.DeliveryStreet, req.DeliveryCity, req.DeliveryZip,
				req.DeliveryLat, req.DeliveryLng, req.SpecialNotes,
				req.IdempotencyKey, itemsBytes, now, now,
			)
			if err == nil {
				_ = tx.Commit(ctx)
			}
		}
	}

	// Publish durable event to NATS JetStream
	if s.publisher != nil {
		_ = s.publisher.PublishOrderEvent(ctx, "orders.created", &events.OrderEventPayload{
			EventID:        uuid.New().String(),
			EventType:      "orders.created",
			OrderID:        orderID,
			UserID:         userID,
			VendorID:       req.VendorID,
			Status:         string(initialStatus),
			TotalAmount:    pricing.TotalAmount,
			IdempotencyKey: req.IdempotencyKey,
			Timestamp:      now,
		})
	}

	platform.GlobalStore.Save(&platform.SharedOrder{
		ID:             orderID,
		UserID:         userID,
		VendorID:       req.VendorID,
		OrderType:      orderType,
		Status:         string(initialStatus),
		Subtotal:       pricing.Subtotal,
		DeliveryFee:    pricing.DeliveryFee,
		Discount:       discount,
		TotalAmount:    total,
		CouponCode:     req.CouponCode,
		PaymentMethod:  req.PaymentMethod,
		PaymentStatus:  paymentStatus,
		DeliveryStreet: req.DeliveryStreet,
		DeliveryCity:   req.DeliveryCity,
		DeliveryZip:    req.DeliveryZip,
		SpecialNotes:   req.SpecialNotes,
		Items:          rawItems,
		CustomerName:   "Valued Customer",
		OrderTime:      now,
		CreatedAt:      now,
		UpdatedAt:      now,
	})

	return &Order{
		ID:             orderID,
		UserID:         userID,
		VendorID:       req.VendorID,
		Status:         initialStatus,
		Subtotal:       pricing.Subtotal,
		DeliveryFee:    pricing.DeliveryFee,
		Discount:       discount,
		TotalAmount:    total,
		CouponCode:     req.CouponCode,
		PaymentMethod:  req.PaymentMethod,
		PaymentStatus:  paymentStatus,
		DeliveryStreet: req.DeliveryStreet,
		DeliveryCity:   req.DeliveryCity,
		DeliveryZip:    req.DeliveryZip,
		DeliveryLat:    req.DeliveryLat,
		DeliveryLng:    req.DeliveryLng,
		SpecialNotes:   req.SpecialNotes,
		IdempotencyKey: &req.IdempotencyKey,
		Items:          itemSummaries,
		CreatedAt:      now,
		UpdatedAt:      now,
	}, nil
}

// MapSharedOrderItems projects raw item maps from memory/JSON into []OrderItemSummary.
func MapSharedOrderItems(items []any) []OrderItemSummary {
	var summaries []OrderItemSummary
	for _, it := range items {
		if m, ok := it.(map[string]any); ok {
			name, _ := m["name"].(string)
			if name == "" {
				name = "Signature Lunch Thali"
			}
			qty := 1
			if q, ok := m["quantity"].(float64); ok && q > 0 {
				qty = int(q)
			} else if q, ok := m["quantity"].(int); ok && q > 0 {
				qty = q
			} else if q, ok := m["qty"].(float64); ok && q > 0 {
				qty = int(q)
			} else if q, ok := m["qty"].(int); ok && q > 0 {
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
			var img *string
			if s, ok := m["image"].(string); ok && s != "" {
				img = &s
			} else if s, ok := m["image_url"].(string); ok && s != "" {
				img = &s
			} else {
				lower := strings.ToLower(name)
				imgAsset := "assets/images/bento.png"
				if strings.Contains(lower, "mizo") {
					imgAsset = "assets/images/pork.png"
				} else if strings.Contains(lower, "naga") {
					imgAsset = "assets/images/chicken.png"
				} else if strings.Contains(lower, "khasi") {
					imgAsset = "assets/images/beef.png"
				}
				img = &imgAsset
			}
			itemID := fmt.Sprintf("%v", m["item_id"])
			if itemID == "" || itemID == "<nil>" {
				itemID = "meal-1"
			}
			summaries = append(summaries, OrderItemSummary{
				ID:        uuid.New().String(),
				ItemID:    itemID,
				Name:      name,
				UnitPrice: platform.FromPaise(price),
				Quantity:  qty,
				Subtotal:  platform.FromPaise(price * int64(qty)),
				Price:     int(price / 100),
				Image:     img,
			})
		}
	}
	if len(summaries) == 0 {
		defaultImg := "assets/images/bento.png"
		summaries = append(summaries, OrderItemSummary{
			ID:        uuid.New().String(),
			ItemID:    "meal-1",
			Name:      "Signature Lunch Thali",
			UnitPrice: platform.FromPaise(20000),
			Quantity:  1,
			Subtotal:  platform.FromPaise(20000),
			Price:     200,
			Image:     &defaultImg,
		})
	}
	return summaries
}

// scanOrder projects a query row into an Order, unmarshalling the items JSON.
func scanOrder(row pgx.Row) (*Order, error) {
	var o Order
	var itemsJSON []byte
	err := row.Scan(
		&o.ID, &o.UserID, &o.VendorID, &o.RiderID, &o.OrderType,
		&o.Status, &o.Subtotal, &o.DeliveryFee, &o.Discount, &o.TotalAmount,
		&o.CouponCode, &o.PaymentMethod, &o.PaymentStatus,
		&o.DeliveryStreet, &o.DeliveryCity, &o.DeliveryZip,
		&o.DeliveryLat, &o.DeliveryLng, &o.SpecialNotes,
		&o.IdempotencyKey, &o.CreatedAt, &o.UpdatedAt, &itemsJSON,
	)
	if err != nil {
		return nil, err
	}
	if len(itemsJSON) > 0 {
		if err := json.Unmarshal(itemsJSON, &o.Items); err != nil {
			var rawSlice []any
			if json.Unmarshal(itemsJSON, &rawSlice) == nil {
				o.Items = MapSharedOrderItems(rawSlice)
			}
		}
	}
	if len(o.Items) == 0 {
		o.Items = MapSharedOrderItems(nil)
	}
	return &o, nil
}

// ListOrders returns the customer's order history, newest first.
func (s *Service) ListOrders(ctx context.Context, userID, orderType string, limit, offset int) ([]*Order, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	orders := make([]*Order, 0)
	if s.db != nil && s.db.Pool != nil {
		query := `
			SELECT id, user_id, vendor_id, rider_id, order_type, status, subtotal_paise, delivery_fee_paise,
			       discount_paise, total_amount_paise, coupon_code, payment_method, payment_status,
			       delivery_street, delivery_city, delivery_zip, delivery_lat, delivery_lng,
			       special_notes, idempotency_key, created_at, updated_at, items
			FROM orders WHERE user_id = $1`
		args := []any{userID}
		if orderType != "" {
			query += " AND order_type = $2"
			args = append(args, orderType)
		}
		query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", len(args)+1, len(args)+2)
		args = append(args, limit, offset)

		rows, err := s.db.Pool.Query(ctx, query, args...)
		if err == nil {
			defer rows.Close()
			for rows.Next() {
				o, err := scanOrder(rows)
				if err == nil {
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
			orders = append(orders, &Order{
				ID:             mo.ID,
				UserID:         mo.UserID,
				VendorID:       mo.VendorID,
				RiderID:        mo.RiderID,
				OrderType:      mo.OrderType,
				Status:         OrderStatus(mo.Status),
				Subtotal:       mo.Subtotal,
				DeliveryFee:    mo.DeliveryFee,
				Discount:       mo.Discount,
				TotalAmount:    mo.TotalAmount,
				CouponCode:     mo.CouponCode,
				PaymentMethod:  mo.PaymentMethod,
				PaymentStatus:  mo.PaymentStatus,
				DeliveryStreet: mo.DeliveryStreet,
				DeliveryCity:   mo.DeliveryCity,
				DeliveryZip:    mo.DeliveryZip,
				SpecialNotes:   mo.SpecialNotes,
				Items:          MapSharedOrderItems(mo.Items),
				CreatedAt:      mo.CreatedAt,
				UpdatedAt:      mo.UpdatedAt,
			})
		}
	}

	return orders, nil
}

// applyFlatDiscount computes a fixed-rupee coupon discount, capped by the
// coupon's max discount and the order subtotal.
func applyFlatDiscount(flatPaise int64, subtotal, maxDiscount platform.Money) platform.Money {
	flat := platform.FromPaise(flatPaise)
	if maxDiscount > 0 && flat > maxDiscount {
		flat = maxDiscount
	}
	if flat > subtotal {
		flat = subtotal
	}
	return flat
}

// CancelOrder allows customers to cancel their pending orders.
func (s *Service) CancelOrder(ctx context.Context, orderID, userID string) error {
	if s.db == nil || s.db.Pool == nil {
		return platform.ErrInternal
	}

	var currentStatus string
	err := s.db.Pool.QueryRow(ctx, `
		SELECT status FROM orders WHERE id = $1 AND user_id = $2
	`, orderID, userID).Scan(&currentStatus)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) || errors.Is(err, pgx.ErrNoRows) {
			return platform.ErrNotFound
		}
		return err
	}

	if err := ValidateTransition(OrderStatus(currentStatus), StatusCancelled); err != nil {
		return fmt.Errorf("%w: order cannot be cancelled in '%s' status", platform.ErrConflict, currentStatus)
	}

	_, err = s.db.Pool.Exec(ctx, `
		UPDATE orders SET status = 'cancelled', updated_at = NOW()
		WHERE id = $1 AND user_id = $2
	`, orderID, userID)

	return err
}
