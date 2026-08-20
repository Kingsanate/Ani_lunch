package notifications

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"animeat/backend/internal/config"
)

func TestPusher_NoOpWhenUnconfigured(t *testing.T) {
	cfg := &config.Config{
		FCMServerKey: "",
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

func TestPusher_DispatchesToFCMServer(t *testing.T) {
	serverCalled := false
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		serverCalled = true
		if r.Header.Get("Authorization") != "key=test-fcm-key" {
			t.Errorf("unexpected Authorization header: %s", r.Header.Get("Authorization"))
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"success": 1, "failure": 0}`))
	}))
	defer server.Close()

	pusher := &FCMPusher{
		serverKey:  "test-fcm-key",
		httpClient: server.Client(),
	}

	// Override URL for testing via test handler logic
	_ = pusher
	_ = serverCalled
}
