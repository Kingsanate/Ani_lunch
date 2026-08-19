package observability

import (
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "animeat_http_requests_total",
			Help: "Total number of HTTP requests processed",
		},
		[]string{"method", "route", "status"},
	)

	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "animeat_http_request_duration_seconds",
			Help:    "HTTP request latency distribution",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "route"},
	)

	httpRequestsInflight = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "animeat_http_requests_inflight",
			Help: "Current number of in-flight HTTP requests",
		},
	)

	dbQueriesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "animeat_db_queries_total",
			Help: "Total number of database queries executed",
		},
		[]string{"operation"},
	)

	cacheHitsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "animeat_cache_operations_total",
			Help: "Total number of cache operations",
		},
		[]string{"operation", "result"},
	)

	eventsPublishedTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "animeat_events_published_total",
			Help: "Total number of NATS events published",
		},
		[]string{"subject"},
	)

	replicaLagGauge = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "animeat_replica_lag_seconds",
			Help: "Streaming replication lag of the read replica in seconds (-1 = unknown)",
		},
	)
)

// Metrics wraps a route pattern in a handler that records request metrics.
// The route label uses the chi route pattern (e.g. /api/v1/orders/{id}) so
// high-cardinality URL params never explode the label space.
func Metrics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		httpRequestsInflight.Inc()
		defer httpRequestsInflight.Dec()

		start := time.Now()
		ww := &statusWriter{ResponseWriter: w, status: http.StatusOK}

		next.ServeHTTP(ww, r)

		route := chi.RouteContext(r.Context()).RoutePattern()
		if route == "" {
			route = "unmatched"
		}

		httpRequestsTotal.WithLabelValues(r.Method, route, strconv.Itoa(ww.status)).Inc()
		httpRequestDuration.WithLabelValues(r.Method, route).Observe(time.Since(start).Seconds())
	})
}

// Handler exposes Prometheus scrape endpoint.
func Handler() http.Handler {
	return promhttp.Handler()
}

// RecordDBQuery increments the DB query counter for a given operation type.
func RecordDBQuery(operation string) {
	dbQueriesTotal.WithLabelValues(operation).Inc()
}

// RecordCacheHit increments cache hit counters.
func RecordCacheHit() {
	cacheHitsTotal.WithLabelValues("get", "hit").Inc()
}

// RecordCacheMiss increments cache miss counters.
func RecordCacheMiss() {
	cacheHitsTotal.WithLabelValues("get", "miss").Inc()
}

// RecordEventPublished increments the event publish counter for a subject.
func RecordEventPublished(subject string) {
	eventsPublishedTotal.WithLabelValues(subject).Inc()
}

// SetReplicaLagSeconds records the current replication lag (Phase 12).
func SetReplicaLagSeconds(seconds float64) {
	replicaLagGauge.Set(seconds)
}

// statusWriter captures the response status code for metrics.
type statusWriter struct {
	http.ResponseWriter
	status int
}

func (w *statusWriter) WriteHeader(status int) {
	w.status = status
	w.ResponseWriter.WriteHeader(status)
}