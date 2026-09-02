package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"animeat/backend/internal/cache"
	"animeat/backend/internal/config"
	"animeat/backend/internal/database"
	"animeat/backend/internal/database/migrate"
	"animeat/backend/internal/events"
	"animeat/backend/internal/middleware"
	"animeat/backend/internal/modules/admin"
	"animeat/backend/internal/modules/catalog"
	"animeat/backend/internal/modules/health"
	"animeat/backend/internal/modules/orders"
	"animeat/backend/internal/modules/payments"
	"animeat/backend/internal/modules/riders"
	"animeat/backend/internal/modules/users"
	"animeat/backend/internal/modules/vendors"
	"animeat/backend/internal/modules/auth"
	"animeat/backend/internal/modules/media"
	"animeat/backend/internal/notifications"
	"animeat/backend/internal/observability"
	"animeat/backend/internal/platform"
	"animeat/backend/internal/realtime"
	"animeat/backend/internal/storage"
	"github.com/go-chi/chi/v5"
	"github.com/nats-io/nats.go"
)

func main() {
	// Configure structured JSON logging
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	slog.Info("starting AniMeat API backend service...")

	// 1. Load configuration
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load configuration", "error", err)
		os.Exit(1)
	}

	// 2. Run database migrations (before connecting pool)
	if cfg.Environment != "test" {
		slog.Info("running database migrations...")
		if err := migrate.RunMigrations(cfg); err != nil {
			slog.Warn("database migration notice", "error", err)
		} else {
			slog.Info("database migrations completed")
		}
	}

	// 3. Initialize database connection pool & Redis cache
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	pg, err := database.NewPostgres(ctx, cfg)
	if err != nil {
		slog.Warn("could not connect to PostgreSQL on startup", "error", err)
	}
	if pg != nil {
		defer pg.Close()
		pg.StartReplicaLagMonitor(ctx, 15*time.Second)
	}

	redisClient, err := cache.NewRedisClient(ctx, cfg.RedisURL)
	if err != nil {
		slog.Warn("could not connect to Redis on startup", "error", err)
	}
	defer redisClient.Close()

	// Initialize NATS JetStream
	natsClient, err := events.NewNATSClient(ctx, cfg.NatsURL)
	if err != nil {
		slog.Warn("could not connect to NATS JetStream on startup", "error", err)
	} else if natsClient != nil {
		defer natsClient.Close()
	}

	var eventPublisher *events.EventPublisher
	if natsClient != nil && natsClient.JS != nil {
		eventPublisher = events.NewEventPublisher(natsClient.JS).
			WithCoreConn(natsClient.Conn)
		pusher := notifications.NewPusher(pg, cfg)
		eventConsumer := events.NewEventConsumer(natsClient.JS, pg).WithPusher(pusher)

		// Start background durable event workers
		_ = eventConsumer.StartKitchenDispatchWorker(ctx)
		_ = eventConsumer.StartRiderBroadcastWorker(ctx)
		_ = eventConsumer.StartNotificationWorker(ctx)
	}

	rateLimiter := middleware.NewRateLimiter(redisClient)

	// 4. Set up HTTP Router & Global Middleware Stack
	r := chi.NewRouter()

	r.Use(middleware.RequestID)
	r.Use(middleware.Logger)
	r.Use(middleware.CORS())
	r.Use(middleware.Recovery)
	r.Use(observability.Metrics)

	// Prometheus scrape endpoint (public, read-only)
	r.Handle("/metrics", observability.Handler())

	// 5. Mount Modules
	healthHandler := health.NewHandler(pg)
	r.Mount("/health", healthHandler.Routes())

	catalogService := catalog.NewService(pg, redisClient)
	catalogHandler := catalog.NewHandler(catalogService)

	ordersService := orders.NewService(pg, redisClient)
	if eventPublisher != nil {
		ordersService.SetPublisher(eventPublisher)
	}
	ordersHandler := orders.NewHandler(ordersService)

	paymentsService := payments.NewService(pg, cfg.RazorpayKeyID, cfg.RazorpayKeySecret)
	if eventPublisher != nil {
		paymentsService.SetPublisher(eventPublisher)
	}
	paymentsHandler := payments.NewHandler(paymentsService, cfg.WebhookSecret)

	usersService := users.NewService(pg)
	usersHandler := users.NewHandler(usersService)

	ridersService := riders.NewService(pg)
	if eventPublisher != nil {
		ridersService.SetPublisher(eventPublisher)
	}
	ridersHandler := riders.NewHandler(ridersService)

	vendorsService := vendors.NewService(pg)
	vendorsHandler := vendors.NewHandler(vendorsService)

	adminService := admin.NewService(pg, redisClient)
	adminHandler := admin.NewHandler(adminService)

	authService := auth.NewService(pg, redisClient, cfg.JWTSecret)
	authHandler := auth.NewHandler(authService, cfg)

	// Media storage (R2) for direct-to-bucket presigned uploads; optional in dev.
	r2Client, err := storage.NewR2Client(ctx, storage.Config{
		AccountID:       cfg.R2AccountID,
		AccessKeyID:     cfg.R2AccessKeyID,
		SecretAccessKey: cfg.R2SecretAccessKey,
		Bucket:          cfg.R2Bucket,
		PublicBase:      cfg.R2PublicBase,
	})
	if err != nil {
		slog.Warn("media storage (R2) not configured; upload endpoints return 503", "error", err)
		r2Client = nil
	}
	mediaHandler := media.NewHandler(r2Client, cfg)

	// Realtime WebSocket gateway: scoped channels (order:{id}, rider:{id},
	// vendor:{id}) fanned out from one shared NATS subscription per process.
	realtimeHub := realtime.NewHub(nil)
	realtimeGateway := realtime.NewGateway(realtimeHub, cfg.JWTSecret, pg)
	realtimeHub.AttachAuthorizer(realtimeGateway.AuthorizeChannel)
	platform.GlobalStore.SetHub(realtimeHub)
	var natsConn *nats.Conn
	if natsClient != nil {
		natsConn = natsClient.Conn
	}
	realtimeBridge := realtime.NewBridge(realtimeHub, natsConn)
	realtimeCtx, cancelRealtime := context.WithCancel(context.Background())
	defer cancelRealtime()
	go realtimeBridge.Start(realtimeCtx)

	// API v1 grouping
	r.Route("/api/v1", func(v1 chi.Router) {
		v1.Get("/", func(w http.ResponseWriter, r *http.Request) {
			platform.RespondJSON(w, http.StatusOK, map[string]interface{}{
				"name":        "AniMeat API",
				"version":     "1.0.0",
				"environment": cfg.Environment,
			})
		})

		// Public cached catalog
		v1.Mount("/catalog", catalogHandler.Routes())

		// Realtime WebSocket (token auth handled inside the gateway)
		v1.Get("/ws", realtimeGateway.HandleWS)

		// Native auth endpoints
		v1.Post("/auth/register", authHandler.Routes()["POST /api/v1/auth/register"])
		v1.Post("/auth/login", authHandler.Routes()["POST /api/v1/auth/login"])
		v1.Post("/auth/exchange", authHandler.Routes()["POST /api/v1/auth/exchange"])
		v1.Post("/auth/refresh", authHandler.Routes()["POST /api/v1/auth/refresh"])

		// Protected endpoints with rate limiting
		v1.Group(func(protected chi.Router) {
			protected.Use(middleware.RequireAuth(cfg.JWTSecret, authService.Denylist()))
			protected.Use(rateLimiter.Limit(300, 1*time.Minute))

			protected.Get("/auth/me", authHandler.Routes()["GET /api/v1/auth/me"])
			protected.Mount("/users", usersHandler.Routes())
			protected.Mount("/orders", ordersHandler.Routes())
			protected.Mount("/riders", ridersHandler.Routes())
			protected.Mount("/vendors", vendorsHandler.Routes())
			protected.Post("/media/upload-url", mediaHandler.PresignUpload)
			protected.Post("/payments/create-intent", paymentsHandler.CreateIntent)
			protected.Post("/auth/logout", authHandler.Routes()["POST /api/v1/auth/logout"])
		})

		// Admin management (double-gated: JWT + DB-resolved admin role)
		v1.Group(func(adminRouter chi.Router) {
			adminRouter.Use(middleware.RequireAuth(cfg.JWTSecret, authService.Denylist()))
			adminRouter.Use(rateLimiter.Limit(60, 1*time.Minute))
			adminRouter.Use(adminHandler.RequireAdmin)
			adminRouter.Mount("/admin", adminHandler.Routes())
		})

		// Public payment webhook
		v1.Post("/payments/webhook", paymentsHandler.HandleWebhook)
	})

	// 6. Start HTTP Server with Graceful Shutdown
	server := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Server runner goroutine
	serverErr := make(chan error, 1)
	go func() {
		slog.Info("server listening", "addr", server.Addr, "env", cfg.Environment)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			serverErr <- err
		}
	}()

	// 7. Wait for termination signals (SIGINT, SIGTERM)
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-serverErr:
		slog.Error("server encountered fatal error", "error", err)
	case sig := <-quit:
		slog.Info("received shutdown signal", "signal", sig.String())
	}

	// 8. Graceful Shutdown with 10s timeout
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("server forced to shutdown", "error", err)
	} else {
		slog.Info("server shutdown gracefully completed")
	}
}
