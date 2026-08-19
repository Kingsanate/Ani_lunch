import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';

// AdminCache is the cache-first facade over Drift for the admin app.
class AdminCache {
  AdminCache._();
  static final AdminCache instance = AdminCache._();

  AppDatabase? _db;

  void init(AppDatabase db) {
    _db = db;
  }

  Future<List<Map<String, dynamic>>> getCached(String entityType) async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.getDataset(entityType);
    return rows
        .map((r) => jsonDecode(r.payload) as Map<String, dynamic>)
        .toList();
  }

  Future<void> cache(String entityType, List<Map<String, dynamic>> rows) async {
    final db = _db;
    if (db == null) return;
    final now = DateTime.now();
    await db.replaceDataset(entityType, rows.map((row) {
      return LocalAdminCacheCompanion(
        entityType: Value(entityType),
        id: Value(row['id']?.toString() ?? ''),
        payload: Value(jsonEncode(row)),
        updatedAt: Value(now),
      );
    }).toList());
  }

  /// Cache-first fetch: returns cached rows immediately when available and
  /// refreshes from [fetcher] in the background (stale-while-revalidate).
  /// Falls back to a plain network fetch on a cold cache.
  Future<List<Map<String, dynamic>>> fetchCacheFirst({
    required String entityType,
    required Future<List<Map<String, dynamic>>> Function() fetcher,
  }) async {
    final cached = await getCached(entityType);
    if (cached.isNotEmpty) {
      // Stale-while-revalidate: serve cache now, refresh in background.
      fetcher().then((fresh) {
        cache(entityType, fresh);
      }).catchError((e) {
        debugPrint('AdminCache refresh ($entityType) error: $e');
      });
      return cached;
    }
    final fresh = await fetcher();
    await cache(entityType, fresh);
    return fresh;
  }
}