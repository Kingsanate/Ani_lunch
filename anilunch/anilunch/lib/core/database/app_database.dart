import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'tables/items_table.dart';
import 'tables/cart_items_table.dart';
import 'tables/orders_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [LocalItems, LocalCartItems, LocalOrders, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    if (kIsWeb) {
      return driftDatabase(
        name: 'animeat_local_db',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
    }
    return driftDatabase(name: 'animeat_local_db');
  }

  // --------------------------------------------------------------------------
  // Catalog Methods
  // --------------------------------------------------------------------------
  Stream<List<LocalItem>> watchAllItems() {
    return (select(localItems)
          ..where((tbl) => tbl.isAvailable.equals(true))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.rating)]))
        .watch();
  }

  Stream<List<LocalItem>> watchItemsByCategory(String category) {
    return (select(localItems)
          ..where((tbl) => tbl.category.equals(category) & tbl.isAvailable.equals(true))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.rating)]))
        .watch();
  }

  Future<void> upsertItems(List<LocalItemsCompanion> itemsList) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(localItems, itemsList);
    });
  }

  // --------------------------------------------------------------------------
  // Cart Methods (Zero Latency, Client-Authoritative)
  // --------------------------------------------------------------------------
  Stream<List<LocalCartItem>> watchCartItems() {
    return (select(localCartItems)..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])).watch();
  }

  Future<void> addToCart(LocalCartItemsCompanion item) async {
    // Check if matching item already exists with same customizations
    final existing = await (select(localCartItems)
          ..where((tbl) => tbl.itemId.equals(item.itemId.value)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(localCartItems)..where((tbl) => tbl.id.equals(existing.id))).write(
        LocalCartItemsCompanion(
          quantity: Value(existing.quantity + (item.quantity.present ? item.quantity.value : 1)),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(localCartItems).insert(item);
    }
  }

  Future<void> updateCartQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await (delete(localCartItems)..where((tbl) => tbl.id.equals(cartItemId))).go();
    } else {
      await (update(localCartItems)..where((tbl) => tbl.id.equals(cartItemId))).write(
        LocalCartItemsCompanion(
          quantity: Value(newQuantity),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    await (delete(localCartItems)..where((tbl) => tbl.id.equals(cartItemId))).go();
  }

  Future<void> clearCart() async {
    await delete(localCartItems).go();
  }

  // --------------------------------------------------------------------------
  // Orders & Sync Queue Methods
  // --------------------------------------------------------------------------
  Stream<List<LocalOrder>> watchUserOrders(String userId) {
    return (select(localOrders)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Future<void> insertLocalOrder(LocalOrdersCompanion order) async {
    await into(localOrders).insert(order);
  }

  Future<void> enqueueSyncTask(SyncQueueCompanion task) async {
    await into(syncQueue).insert(task);
  }

  Future<List<SyncQueueData>> getPendingSyncTasks() {
    final now = DateTime.now();
    return (select(syncQueue)
          ..where((tbl) =>
              tbl.status.equals('pending') |
              (tbl.status.equals('failed') & (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerOrEqualValue(now))))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  Future<void> markSyncTaskCompleted(String taskId) async {
    await (update(syncQueue)..where((tbl) => tbl.id.equals(taskId))).write(
      SyncQueueCompanion(
        status: const Value('completed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markSyncTaskFailed(String taskId, String error, DateTime nextRetry) async {
    final task = await (select(syncQueue)..where((tbl) => tbl.id.equals(taskId))).getSingle();
    await (update(syncQueue)..where((tbl) => tbl.id.equals(taskId))).write(
      SyncQueueCompanion(
        status: const Value('failed'),
        attemptCount: Value(task.attemptCount + 1),
        lastError: Value(error),
        nextRetryAt: Value(nextRetry),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
