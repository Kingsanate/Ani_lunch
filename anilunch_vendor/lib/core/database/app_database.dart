import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/vendor_orders_table.dart';
import 'tables/vendor_profile_table.dart';
import 'tables/products_table.dart';
import 'tables/stats_table.dart';

part 'app_database.g.dart';

// Active statuses = in-flight orders (mirrors the UI's active filter)
const List<String> activeOrderStatuses = [
  'pending',
  'preparing',
  'ready_for_pickup',
  'assigned',
  'accepted',
  'picked_up',
];

const List<String> historyOrderStatuses = [
  'completed',
  'cancelled',
  'refunded',
  'delivered',
];

@DriftDatabase(
    tables: [LocalVendorOrders, LocalVendorProfile, LocalProduct, LocalStats])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'animeat_vendor_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Orders Cache
  // --------------------------------------------------------------------------
  Future<List<LocalVendorOrder>> getOrders({required bool active}) {
    final query = select(localVendorOrders)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.orderTime)]);
    query.where((tbl) => tbl.status.isIn(
        active ? activeOrderStatuses : historyOrderStatuses));
    return query.get();
  }

  Future<void> replaceAllOrders(
      List<LocalVendorOrdersCompanion> orders) async {
    await batch((b) {
      b.deleteWhere(localVendorOrders, (tbl) => const Constant(true));
      if (orders.isNotEmpty) {
        b.insertAll(localVendorOrders, orders);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Profile Cache
  // --------------------------------------------------------------------------
  Future<LocalVendorProfileData?> getProfile(String id) {
    return (select(localVendorProfile)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertProfile(LocalVendorProfileCompanion profile) async {
    await into(localVendorProfile).insertOnConflictUpdate(profile);
  }

  // --------------------------------------------------------------------------
  // Products Cache
  // --------------------------------------------------------------------------
  Future<List<LocalProductData>> getProducts() {
    return (select(localProduct)..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  Future<void> replaceAllProducts(List<LocalProductCompanion> items) async {
    await batch((b) {
      b.deleteWhere(localProduct, (tbl) => const Constant(true));
      if (items.isNotEmpty) {
        b.insertAll(localProduct, items);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Stats Cache
  // --------------------------------------------------------------------------
  Future<LocalStat?> getStats(String vendorId) {
    return (select(localStats)..where((tbl) => tbl.vendorId.equals(vendorId)))
        .getSingleOrNull();
  }

  Future<void> upsertStats(LocalStatsCompanion statsRow) async {
    await into(localStats).insertOnConflictUpdate(statsRow);
  }
}