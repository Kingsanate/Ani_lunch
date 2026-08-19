package cache

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/redis/go-redis/v9"
)

type RedisClient struct {
	Client *redis.Client
}

// NewRedisClient initializes and validates a Redis connection pool.
func NewRedisClient(ctx context.Context, redisURL string) (*RedisClient, error) {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse Redis URL: %w", err)
	}

	opt.PoolSize = 50
	opt.MinIdleConns = 10
	opt.ConnMaxIdleTime = 5 * time.Minute

	client := redis.NewClient(opt)

	// Test connectivity with short timeout
	pingCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()

	if err := client.Ping(pingCtx).Err(); err != nil {
		slog.Warn("Redis ping failed on startup (will retry on demand)", "error", err)
	} else {
		slog.Info("Redis connection pool initialized successfully", "addr", opt.Addr)
	}

	return &RedisClient{Client: client}, nil
}

// Get retrieves and unmarshals a cached JSON value into target dest.
func (r *RedisClient) Get(ctx context.Context, key string, dest interface{}) error {
	if r.Client == nil {
		return errors.New("redis client not initialized")
	}

	val, err := r.Client.Get(ctx, key).Bytes()
	if err != nil {
		return err // returns redis.Nil on cache miss
	}

	return json.Unmarshal(val, dest)
}

// Set marshals and stores a value in Redis with a time-to-live expiration.
func (r *RedisClient) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	if r.Client == nil {
		return errors.New("redis client not initialized")
	}

	bytes, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("failed to marshal cache value: %w", err)
	}

	return r.Client.Set(ctx, key, bytes, ttl).Err()
}

// Delete removes one or more keys from Redis.
func (r *RedisClient) Delete(ctx context.Context, keys ...string) error {
	if r.Client == nil || len(keys) == 0 {
		return nil
	}
	return r.Client.Del(ctx, keys...).Err()
}

// DeletePattern scans and removes all keys matching a glob pattern (e.g. "catalog:*").
func (r *RedisClient) DeletePattern(ctx context.Context, pattern string) error {
	if r.Client == nil {
		return nil
	}

	var cursor uint64
	for {
		keys, nextCursor, err := r.Client.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return err
		}

		if len(keys) > 0 {
			if err := r.Client.Del(ctx, keys...).Err(); err != nil {
				return err
			}
		}

		cursor = nextCursor
		if cursor == 0 {
			break
		}
	}

	return nil
}

// Ping verifies Redis server connectivity.
func (r *RedisClient) Ping(ctx context.Context) error {
	if r.Client == nil {
		return errors.New("redis client is nil")
	}
	return r.Client.Ping(ctx).Err()
}

// Close gracefully closes the Redis connection pool.
func (r *RedisClient) Close() {
	if r.Client != nil {
		_ = r.Client.Close()
	}
}
