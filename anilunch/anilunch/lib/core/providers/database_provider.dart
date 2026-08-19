import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../sync/sync_engine.dart';

// appDatabaseProvider exposes the singleton Drift SQLite database instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// syncEngineProvider exposes the sync coordinator and manages its lifecycle.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabase = Supabase.instance.client;
  final engine = SyncEngine(db: db, supabase: supabase);

  // Automatically start background sync
  engine.startPeriodicSync();
  ref.onDispose(() => engine.stop());

  return engine;
});
