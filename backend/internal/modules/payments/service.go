package payments

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"animeat/backend/internal/database"
	"animeat/backend/internal/events"
	"animeat/backend/internal/modules/orders"
	"animeat/backend/internal/platform"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type Service struct {
	db        *database.Postgres
	keyID     string
	keySecret string
	publisher *events.EventPublisher
}

func NewService(db *database.Postgres, keyID, keySecret string) *Service {
	return &Service{
		db:        db,
		keyID:     keyID,
		keySecret: keySecret,
	}
}

func (s *Service) SetPublisher(pub *events.EventPublisher) {
	s.publisher = pub
}

// PaymentIntentResponse contains URLs and token IDs for Razorpay/UPI payment completion.
type PaymentIntentResponse struct {
	OrderID     string         `json:"order_id"`
	TotalAmount platform.Money `json:"total_amount"` // In integer paise
	Rupees      float64        `json:"rupees"`
	Currency    string         `json:"currency"`
	PaymentLink string         `json:"payment_link"`
	UPIIntent   string         `json:"upi_intent"`
	KeyID       string         `json:"key_id"`
}

// CreatePaymentIntent verifies order ownership and returns a payment link / UPI intent.
func (s *Service) CreatePaymentIntent(ctx context.Context, orderID, userID string) (*PaymentIntentResponse, error) {
	if s.db == nil || s.db.Pool == nil {
		return nil, platform.ErrInternal
	}

	var totalPaise int64
	var status string
	var paymentStatus string

	err := s.db.Pool.QueryRow(ctx, `
		SELECT total_amount_paise, status, payment_status 
		FROM orders 
		WHERE id = $1 AND user_id = $2
	`, orderID, userID).Scan(&totalPaise, &status, &paymentStatus)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("%w: order '%s' not found", platform.ErrNotFound, orderID)
		}
		return nil, fmt.Errorf("failed to fetch order: %w", err)
	}

	if paymentStatus == "paid" {
		return nil, fmt.Errorf("%w: order is already paid", platform.ErrConflict)
	}

	money := platform.FromPaise(totalPaise)
	rupees := money.ToRupees()

	// Build UPI intent string (e.g. upi://pay?pa=merchant@upi&pn=AniMeat&am=100.50&tr=ORD-123)
	upiIntent := fmt.Sprintf(
		"upi://pay?pa=animeat@okaxis&pn=AniMeat&am=%.2f&tr=%s&cu=INR",
		rupees, orderID,
	)

	// Build payment gateway link
	paymentLink := fmt.Sprintf(
		"https://rzp.io/i/animeat-%s",
		orderID,
	)

	return &PaymentIntentResponse{
		OrderID:     orderID,
		TotalAmount: money,
		Rupees:      rupees,
		Currency:    "INR",
		PaymentLink: paymentLink,
		UPIIntent:   upiIntent,
		KeyID:       s.keyID,
	}, nil
}

// VerifyWebhookSignature verifies HMAC-SHA256 signature from payment gateways.
func VerifyWebhookSignature(payload []byte, receivedSignature, webhookSecret string) bool {
	if receivedSignature == "" || webhookSecret == "" {
		return false
	}

	mac := hmac.New(sha256.New, []byte(webhookSecret))
	mac.Write(payload)
	expectedSignature := hex.EncodeToString(mac.Sum(nil))

	return hmac.Equal([]byte(expectedSignature), []byte(receivedSignature))
}

// HandlePaymentSuccess transitions an order to confirmed/paid status upon payment completion.
func (s *Service) HandlePaymentSuccess(ctx context.Context, orderID, paymentID string) error {
	if s.db == nil || s.db.Pool == nil {
		return platform.ErrInternal
	}

	var currentStatus string
	err := s.db.Pool.QueryRow(ctx, `
		SELECT status FROM orders WHERE id = $1
	`, orderID).Scan(&currentStatus)
	if err != nil {
		return fmt.Errorf("order not found: %w", err)
	}

	if err := orders.ValidateTransition(orders.OrderStatus(currentStatus), orders.StatusConfirmed); err != nil {
		// If already confirmed or beyond, do not error out (idempotent webhook replay)
		if currentStatus == string(orders.StatusConfirmed) || currentStatus == string(orders.StatusPreparing) {
			return nil
		}
		return err
	}

	now := time.Now().UTC()
	_, err = s.db.Pool.Exec(ctx, `
		UPDATE orders 
		SET status = 'confirmed', payment_status = 'paid', updated_at = $1
		WHERE id = $2
	`, now, orderID)

	if err == nil && s.publisher != nil {
		_ = s.publisher.PublishOrderEvent(ctx, "orders.paid", &events.OrderEventPayload{
			EventID:   uuid.New().String(),
			EventType: "orders.paid",
			OrderID:   orderID,
			Status:    "confirmed",
			Timestamp: now,
		})
	}

	return err
}
