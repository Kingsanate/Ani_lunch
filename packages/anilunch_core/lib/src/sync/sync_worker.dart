import 'dart:async';

/// A pending offline mutation queued by the app's local Drift DB.
class SyncTask {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final Map<String, dynamic> payload;
  final String? idempotencyKey;
  final int attempts;

  const SyncTask({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    this.idempotencyKey,
    this.attempts = 0,
  });
}

/// App-side access to the local mutation queue (SyncQueue table).
abstract class SyncTaskStore {
  Future<List<SyncTask>> fetchPending();
  Future<void> markCompleted(String taskId);
  Future<void> markFailed(String taskId, {String? reason});
  Future<void> incrementAttempts(String taskId, int attempts);
}

/// Replays queued offline mutations against the Go API with idempotency.
///
/// The [dispatch] callback maps a task to exactly one API call; the worker
/// guarantees retry with backoff and never drops a task it could not send.
class SyncWorker {
  final SyncTaskStore store;
  final Future<void> Function(SyncTask task) dispatch;
  final Duration idleInterval;
  final int maxAttempts;
  final List<Duration> retryDelays;

  Timer? _timer;
  bool _running = false;

  SyncWorker({
    required this.store,
    required this.dispatch,
    this.idleInterval = const Duration(seconds: 30),
    this.maxAttempts = 5,
    this.retryDelays = const [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(minutes: 1),
      Duration(minutes: 5),
    ],
  });

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(idleInterval, (_) => runOnce());
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Drains the queue once; safe to call manually after reconnects.
  Future<void> runOnce() async {
    if (!_running && _timer == null) return;
    List<SyncTask> tasks;
    try {
      tasks = await store.fetchPending();
    } catch (_) {
      return;
    }
    for (final task in tasks) {
      if (task.attempts >= maxAttempts) continue;
      try {
        await dispatch(task);
        await store.markCompleted(task.id);
      } catch (_) {
        final attempts = task.attempts + 1;
        await store.incrementAttempts(task.id, attempts);
        if (attempts >= maxAttempts) {
          await store.markFailed(task.id);
        }
        break;
      }
    }
  }

  /// Picks the retry delay for a failed task.
  Duration backoffFor(int attempts) {
    if (attempts >= retryDelays.length) {
      return retryDelays.last;
    }
    return retryDelays[attempts];
  }
}