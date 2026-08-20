import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/orders_table.dart';
import 'tables/rider_profile_table.dart';
import 'tables/sync_queue_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [LocalOrders, LocalRiderProfile, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'animeat_rider_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Rider Orders Cache
  // --------------------------------------------------------------------------
  Stream<List<LocalOrder>> watchRiderOrders(String riderId) {
    return (select(localOrders)
          ..where((tbl) => tbl.riderId.equals(riderId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
        .watch();
  }

  Future<List<LocalOrder>> getRiderOrders(String riderId) {
    return (select(localOrders)
          ..where((tbl) => tbl.riderId.equals(riderId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
        .get();
  }

  Future<void> upsertOrders(List<LocalOrdersCompanion> orders) async {
    if (orders.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(localOrders, orders);
    });
  }

  /// Server-authoritative reconciliation: replaces this rider's cached feed
  /// with the freshly fetched set (rider app never creates orders offline).
  Future<void> replaceRiderOrders(
      String riderId, List<LocalOrdersCompanion> orders) async {
    await batch((b) {
      b.deleteWhere(
          localOrders, (tbl) => tbl.riderId.equals(riderId));
      if (orders.isNotEmpty) {
        b.insertAll(localOrders, orders);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Rider Profile Cache
  // --------------------------------------------------------------------------
  Future<LocalRiderProfileData?> getRiderProfile(String id) {
    return (select(localRiderProfile)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertRiderProfile(LocalRiderProfileCompanion profile) async {
    await into(localRiderProfile).insertOnConflictUpdate(profile);
  }

  // --------------------------------------------------------------------------
  // Sync Queue
  // --------------------------------------------------------------------------
  Future<void> enqueueSyncTask(SyncQueueCompanion task) async {
    await into(syncQueue).insert(task);
  }

  Future<List<SyncQueueData>> getPendingSyncTasks() {
    final now = DateTime.now();
    return (select(syncQueue)
          ..where((tbl) =>
              tbl.status.equals('pending') |
              (tbl.status.equals('failed') &
                  (tbl.nextRetryAt.isNull() |
                      tbl.nextRetryAt.isSmallerOrEqualValue(now))))
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

  Future<void> markSyncTaskFailed(
      String taskId, String error, DateTime nextRetry) async {
    final task =
        await (select(syncQueue)..where((tbl) => tbl.id.equals(taskId)))
            .getSingle();
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