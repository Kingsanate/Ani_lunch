package payments

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"testing"
)

func TestVerifyWebhookSignature(t *testing.T) {
	secret := "test_webhook_secret_key_12345"
	payload := []byte(`{"event":"payment.captured","order_id":"ORD-987","amount":15000}`)

	// Compute valid signature
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(payload)
	validSignature := hex.EncodeToString(mac.Sum(nil))

	// 1. Test valid signature
	if !VerifyWebhookSignature(payload, validSignature, secret) {
		t.Errorf("expected valid signature to pass verification")
	}

	// 2. Test tampered payload
	tamperedPayload := []byte(`{"event":"payment.captured","order_id":"ORD-987","amount":99999}`)
	if VerifyWebhookSignature(tamperedPayload, validSignature, secret) {
		t.Errorf("expected tampered payload to fail verification")
	}

	// 3. Test wrong secret
	if VerifyWebhookSignature(payload, validSignature, "wrong_secret") {
		t.Errorf("expected wrong secret to fail verification")
	}

	// 4. Test empty signature
	if VerifyWebhookSignature(payload, "", secret) {
		t.Errorf("expected empty signature to fail verification")
	}
}
