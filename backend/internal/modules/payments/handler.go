package payments

import (
	"encoding/json"
	"io"
	"net/http"

	"animeat/backend/internal/middleware"
	"animeat/backend/internal/platform"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	service       *Service
	webhookSecret string
}

func NewHandler(service *Service, webhookSecret string) *Handler {
	return &Handler{
		service:       service,
		webhookSecret: webhookSecret,
	}
}

func (h *Handler) Routes() chi.Router {
	r := chi.NewRouter()

	r.Post("/create-intent", h.CreateIntent)
	r.Post("/webhook", h.HandleWebhook)

	return r
}

type CreateIntentRequest struct {
	OrderID string `json:"order_id"`
}

// CreateIntent handles payment link generation for a confirmed/pending order.
func (h *Handler) CreateIntent(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if userID == "" {
		platform.RespondError(w, http.StatusUnauthorized, "UNAUTHORIZED", "Authentication required", "")
		return
	}

	var req CreateIntentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_BODY", "Failed to parse JSON body", err.Error())
		return
	}

	if req.OrderID == "" {
		platform.RespondError(w, http.StatusBadRequest, "MISSING_ORDER_ID", "Order ID is required", "")
		return
	}

	intent, err := h.service.CreatePaymentIntent(r.Context(), req.OrderID, userID)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "PAYMENT_INTENT_FAILED", err.Error(), "")
		return
	}

	platform.RespondJSON(w, http.StatusOK, intent)
}

// HandleWebhook validates webhook HMAC signatures and marks orders paid.
func (h *Handler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		platform.RespondError(w, http.StatusBadRequest, "READ_ERROR", "Failed to read webhook payload", "")
		return
	}
	defer r.Body.Close()

	signature := r.Header.Get("X-Razorpay-Signature")
	if signature == "" {
		signature = r.Header.Get("X-Webhook-Signature")
	}

	if !VerifyWebhookSignature(body, signature, h.webhookSecret) {
		platform.RespondError(w, http.StatusUnauthorized, "INVALID_SIGNATURE", "Webhook signature verification failed", "")
		return
	}

	var payload struct {
		Event   string `json:"event"`
		Payload struct {
			Payment struct {
				Entity struct {
					ID      string `json:"id"`
					OrderID string `json:"order_id"`
					Status  string `json:"status"`
				} `json:"entity"`
			} `json:"payment"`
		} `json:"payload"`
		OrderID   string `json:"order_id"`   // Fallback direct format
		PaymentID string `json:"payment_id"` // Fallback direct format
	}

	if err := json.Unmarshal(body, &payload); err != nil {
		platform.RespondError(w, http.StatusBadRequest, "INVALID_PAYLOAD", "Could not unmarshal webhook payload", "")
		return
	}

	orderID := payload.Payload.Payment.Entity.OrderID
	if orderID == "" {
		orderID = payload.OrderID
	}

	paymentID := payload.Payload.Payment.Entity.ID
	if paymentID == "" {
		paymentID = payload.PaymentID
	}

	if orderID != "" {
		_ = h.service.HandlePaymentSuccess(r.Context(), orderID, paymentID)
	}

	platform.RespondJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}
