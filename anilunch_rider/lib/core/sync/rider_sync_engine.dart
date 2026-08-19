import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cache/order_cache.dart';
import '../database/app_database.dart';
import '../providers/api_provider.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';

// RiderSyncEngine coordinates background sync between Drift SQLite and
// Supabase: pull orders + profile down (server-authoritative), and drain the
// mutation queue (online status, GPS location) with at-least-once delivery.
class RiderSyncEngine {
  RiderSyncEngine._();
  static final RiderSyncEngine instance = RiderSyncEngine._();

  AppDatabase? _db;
  Timer? _timer;
  bool _isSyncing = false;

  void init(AppDatabase db) {
    _db = db;
  }

  void startPeriodicSync({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow());
    syncNow();
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> syncNow() async {
    final db = _db;
    final uid = AuthService.currentUser?.id;
    if (db == null || uid == null || _isSyncing) return;
    _isSyncing = true;
    try {
      await syncOrdersDown(uid);
      await syncRiderDown(uid);
      await processPendingMutations();
    } catch (e) {
      debugPrint('RiderSyncEngine error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Pull: orders assigned to this rider (server authoritative) ────────────
  Future<void> syncOrdersDown(String riderId) async {
    final mine = await OrderService.fetchMyOrders(riderId);
    final available = await OrderService.fetchAvailableOrders(riderId);
    final active = await OrderService.fetchActiveOrder(riderId);

    final byId = <String, OrderModel>{};
    for (final order in [...mine, ...available]) {
      byId[order.id] = order;
    }
    if (active != null) {
      byId[active.id] = active;
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final ta = a.createdAt;
        final tb = b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

    await OrderCache.instance.replaceOrders(riderId, merged);
  }

  // ── Pull: rider profile ───────────────────────────────────────────────────
  Future<void> syncRiderDown(String riderId) async {
    final rider = await AuthService.loadRiderProfile();
    if (rider != null) {
      await OrderCache.instance.cacheProfile(rider);
    }
  }

  // ── Queue safe mutations (online status, GPS) ─────────────────────────────
  Future<void> enqueue(
      {required String riderId,
      required String action,
      required Map<String, dynamic> payload}) async {
    final db = _db;
    if (db == null) return;
    final now = DateTime.now();
    await db.enqueueSyncTask(SyncQueueCompanion(
      id: Value('${now.microsecondsSinceEpoch}'),
      entityType: const Value('rider'),
      entityId: Value(riderId),
      action: Value(action),
      payload: Value(jsonEncode(payload)),
      idempotencyKey: Value('${now.microsecondsSinceEpoch}'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  Future<void> processPendingMutations() async {
    final db = _db;
    if (db == null) return;
    final pending = await db.getPendingSyncTasks();
    if (pending.isEmpty) return;

    for (final task in pending) {
      try {
        await _executeTask(task);
        await db.markSyncTaskCompleted(task.id);
      } catch (e) {
        final backoffSecs =
            min(60, pow(2, task.attemptCount + 1) * 2).toInt();
        final nextRetry = DateTime.now().add(Duration(seconds: backoffSecs));
        await db.markSyncTaskFailed(task.id, e.toString(), nextRetry);
      }
    }
  }

  Future<void> _executeTask(SyncQueueData task) async {
    final payload = jsonDecode(task.payload) as Map<String, dynamic>;
    final api = AniApi.instance.api;

    switch (task.entityType) {
      case 'rider':
        switch (task.action) {
          case 'update_online':
            await api.riders.setAvailability(payload['is_online'] ?? false);
            break;
          case 'update_location':
            await api.riders.updateLocation(
              (payload['latitude'] as num).toDouble(),
              (payload['longitude'] as num).toDouble(),
            );
            break;
          default:
            debugPrint('Unknown rider sync action: ${task.action}');
        }
        break;
      default:
        debugPrint('Unknown sync entityType: ${task.entityType}');
    }
  }
}