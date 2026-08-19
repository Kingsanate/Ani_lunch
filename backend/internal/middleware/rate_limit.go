package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"time"

	"animeat/backend/internal/cache"
	"animeat/backend/internal/platform"
)

type RateLimiter struct {
	redis      *cache.RedisClient
	localStore sync.Map
}

type localRateEntry struct {
	count     int
	resetTime time.Time
}

func NewRateLimiter(redisClient *cache.RedisClient) *RateLimiter {
	return &RateLimiter{
		redis: redisClient,
	}
}

// Limit returns a middleware that limits requests to maxRequests per window.
func (rl *RateLimiter) Limit(maxRequests int, window time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Extract client key (prefer authenticated user_id, fallback to IP)
			clientKey := GetUserID(r.Context())
			if clientKey == "" {
				clientKey = r.RemoteAddr
			}

			allowed, remaining, retryAfter := rl.allowRequest(r.Context(), clientKey, maxRequests, window)

			w.Header().Set("X-RateLimit-Limit", strconv.Itoa(maxRequests))
			w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(remaining))

			if !allowed {
				w.Header().Set("Retry-After", strconv.Itoa(int(retryAfter.Seconds())))
				platform.RespondError(w, http.StatusTooManyRequests, "RATE_LIMIT_EXCEEDED", "Too many requests. Please try again later.", fmt.Sprintf("Retry after %d seconds", int(retryAfter.Seconds())))
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func (rl *RateLimiter) allowRequest(ctx context.Context, key string, maxRequests int, window time.Duration) (bool, int, time.Duration) {
	// 1. If Redis is available, use Redis atomic increment
	if rl.redis != nil && rl.redis.Client != nil {
		redisKey := fmt.Sprintf("ratelimit:%s:%d", key, time.Now().Unix()/(int64(window.Seconds())))
		pipe := rl.redis.Client.Pipeline()
		incrCmd := pipe.Incr(ctx, redisKey)
		pipe.Expire(ctx, redisKey, window*2)
		_, err := pipe.Exec(ctx)

		if err == nil {
			count := int(incrCmd.Val())
			if count > maxRequests {
				return false, 0, window
			}
			return true, maxRequests - count, 0
		}
	}

	// 2. In-memory fallback
	now := time.Now()
	val, _ := rl.localStore.Load(key)
	var entry localRateEntry

	if val != nil {
		entry = val.(localRateEntry)
	}

	if now.After(entry.resetTime) {
		entry = localRateEntry{
			count:     1,
			resetTime: now.Add(window),
		}
		rl.localStore.Store(key, entry)
		return true, maxRequests - 1, 0
	}

	if entry.count >= maxRequests {
		return false, 0, entry.resetTime.Sub(now)
	}

	entry.count++
	rl.localStore.Store(key, entry)
	return true, maxRequests - entry.count, 0
}
