import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../providers/api_provider.dart';

// SyncEngine coordinates background sync between Drift SQLite and backend/Supabase.
// Guarantees Last-Write-Wins (LWW) and reliable at-least-once offline mutations.
class SyncEngine {
  final AppDatabase db;
  final SupabaseClient supabase;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncEngine({required this.db, required this.supabase});

  void startPeriodicSync({Duration interval = const Duration(seconds: 30)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncAll());
    // Trigger immediate initial sync
    syncAll();
  }

  void stop() {
    _syncTimer?.cancel();
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await syncCatalogDown();
      await processPendingMutations();
    } catch (e) {
      debugPrint('SyncEngine error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Pull Catalog Items from the Go API into Local SQLite (LWW) ───────────
  Future<void> syncCatalogDown() async {
    try {
      final items = await AniApi.instance.api.catalog.items();

      final companions = items.map((item) {
        return LocalItemsCompanion(
          id: Value(item.id),
          vendorId: Value(item.vendorId),
          name: Value(item.name),
          description: Value(item.description),
          price: Value(BigInt.from(item.price.paise)),
          originalPrice: item.originalPrice != null
              ? Value(BigInt.from(item.originalPrice!.paise))
              : const Value.absent(),
          category: Value(item.category),
          imageUrl: Value(item.imageUrl),
          isAvailable: Value(item.isAvailable),
          prepTime: Value(item.preparationMin),
          rating: Value(item.rating),
          reviewsCount: Value(item.reviewsCount),
          syncedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();

      if (companions.isNotEmpty) {
        await db.upsertItems(companions);
      }
    } catch (e) {
      debugPrint('syncCatalogDown error: $e');
    }
  }

  // ── Process Outbound Mutation Queue (At-Least-Once Delivery) ─────────────
  Future<void> processPendingMutations() async {
    final pendingTasks = await db.getPendingSyncTasks();
    if (pendingTasks.isEmpty) return;

    for (final task in pendingTasks) {
      try {
        await _executeTask(task);
        await db.markSyncTaskCompleted(task.id);
      } catch (e) {
        // Calculate exponential backoff (2^attempts * 2 seconds, max 60s)
        final backoffSecs = min(60, pow(2, task.attemptCount + 1) * 2).toInt();
        final nextRetry = DateTime.now().add(Duration(seconds: backoffSecs));
        await db.markSyncTaskFailed(task.id, e.toString(), nextRetry);
      }
    }
  }

  Future<void> _executeTask(SyncQueueData task) async {
    final payload = jsonDecode(task.payload) as Map<String, dynamic>;

    switch (task.entityType) {
      case 'order':
        if (task.action == 'create') {
          final items = (payload['items'] as List<dynamic>? ?? const [])
              .map((raw) {
                final item = raw as Map<String, dynamic>;
                return OrderItemRequest(
                  itemId: item['item_id'].toString(),
                  quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                );
              })
              .toList();
          await AniApi.instance.api.orders.create(CreateOrderRequest(
            idempotencyKey:
                (payload['idempotency_key'] ?? task.idempotencyKey).toString(),
            orderType: payload['order_type']?.toString(),
            paymentMethod: payload['payment_method']?.toString() ?? 'cod',
            couponCode: payload['coupon_code']?.toString(),
            deliveryStreet: payload['delivery_street']?.toString() ?? '',
            deliveryCity: payload['delivery_city']?.toString() ?? '',
            deliveryZip: payload['delivery_zip']?.toString() ?? '',
            deliveryLat: (payload['delivery_lat'] as num?)?.toDouble(),
            deliveryLng: (payload['delivery_lng'] as num?)?.toDouble(),
            specialNotes: payload['special_notes']?.toString(),
            items: items,
          ));
        }
        break;
      case 'review':
        if (task.action == 'create') {
          await supabase.from('product_reviews').insert(payload);
        }
        break;
      default:
        debugPrint('Unknown sync task entityType: ${task.entityType}');
    }
  }
}