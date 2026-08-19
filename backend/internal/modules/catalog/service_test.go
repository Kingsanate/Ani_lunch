package catalog

import (
	"testing"
	"time"
)

func TestJitteredTTLStaysWithinBounds(t *testing.T) {
	base := 5 * time.Minute

	for i := 0; i < 100; i++ {
		got := jitteredTTL(base)
		min := time.Duration(float64(base) * (1 - jitterFactor))
		max := time.Duration(float64(base) * (1 + jitterFactor))

		if got < min || got > max {
			t.Fatalf("jittered TTL %v outside bounds [%v, %v]", got, min, max)
		}
	}
}

func TestJitteredTTLVaries(t *testing.T) {
	base := 5 * time.Minute
	seen := map[time.Duration]bool{}

	for i := 0; i < 50; i++ {
		seen[jitteredTTL(base)] = true
	}

	if len(seen) < 2 {
		t.Fatalf("expected jitter to produce varying TTLs, got %d distinct values", len(seen))
	}
}

func TestCacheGetWithNilCache(t *testing.T) {
	s := NewService(nil, nil)
	if s.cacheGet(t.Context(), "key", &struct{}{}) {
		t.Fatal("expected cache miss when cache is nil")
	}
}