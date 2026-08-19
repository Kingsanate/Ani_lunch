import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

// catalogItemsProvider streams all available items from local Drift SQLite.
final catalogItemsProvider = StreamProvider<List<LocalItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllItems();
});

// categoryItemsProvider streams items filtered by category family.
final categoryItemsProvider = StreamProvider.family<List<LocalItem>, String>((ref, category) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchItemsByCategory(category);
});
