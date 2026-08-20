package notifications

import (
	"context"
	"testing"

	"animeat/backend/internal/config"
)

func TestPusher_NoOpWhenUnconfigured(t *testing.T) {
	cfg := &config.Config{
		FCMServerKey:          "",
		FCMServiceAccountFile: "",
		FCMServiceAccountJSON: "",
	}
	p := NewPusher(nil, cfg)

	err := p.SendToTokens(context.Background(), []string{"tok-1", "tok-2"}, "Test", "Message", nil)
	if err != nil {
		t.Fatalf("expected nil error on unconfigured FCM pusher, got: %v", err)
	}

	err = p.SendToUser(context.Background(), "user-1", "Test", "Message", nil)
	if err != nil {
		t.Fatalf("expected nil error on unconfigured SendToUser, got: %v", err)
	}
}

func TestPusher_EmptyTokensNoOp(t *testing.T) {
	p := NewPusher(nil, &config.Config{FCMServerKey: "dummy-key"})
	err := p.SendToTokens(context.Background(), nil, "Test", "Message", nil)
	if err != nil {
		t.Fatalf("expected nil error for empty tokens, got: %v", err)
	}
}

func TestPusher_LoadsServiceAccountFromConfig(t *testing.T) {
	cfg := &config.Config{
		FCMServiceAccountFile: "../../firebase-service-account.json",
	}
	p := NewPusher(nil, cfg)
	fcmPusher, ok := p.(*FCMPusher)
	if !ok {
		t.Fatal("expected *FCMPusher type")
	}

	if fcmPusher.sa != nil {
		if fcmPusher.sa.ProjectID != "anilunch-5aa5b" {
			t.Errorf("unexpected project ID: %s", fcmPusher.sa.ProjectID)
		}
		if fcmPusher.parsedKey == nil {
			t.Error("expected parsed RSA private key to be non-nil")
		}
	}
}
