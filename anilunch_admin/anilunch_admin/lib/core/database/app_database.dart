import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/admin_cache_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [LocalAdminCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'animeat_admin_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  Future<List<LocalAdminCacheData>> getDataset(String entityType) {
    return (select(localAdminCache)..where((tbl) => tbl.entityType.equals(entityType)))
        .get();
  }

  Future<void> replaceDataset(
      String entityType, List<LocalAdminCacheCompanion> rows) async {
    await batch((b) {
      b.deleteWhere(localAdminCache, (tbl) => tbl.entityType.equals(entityType));
      if (rows.isNotEmpty) {
        b.insertAll(localAdminCache, rows);
      }
    });
  }
}