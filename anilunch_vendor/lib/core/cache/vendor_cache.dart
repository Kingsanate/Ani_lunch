import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';

// VendorCache is the cache-first facade over Drift for the vendor app.
// Orders streams are "cache-through": cached rows are emitted immediately on
// subscribe (no blocking spinner on cold start), then live Supabase stream
// events refresh the cache and re-emit.
class VendorCache {
  VendorCache._();
  static final VendorCache instance = VendorCache._();

  AppDatabase? _db;

  void init(AppDatabase db) {
    _db = db;
  }

  bool get isReady => _db != null;

  // ── Orders (cache-through) ────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> cacheThrough({
    required bool active,
    required Stream<List<Map<String, dynamic>>> live,
  }) {
    final db = _db;
    if (db == null) return live;

    return Stream.multi((controller) {
      // 1. Emit cached rows immediately (cache-first rendering).
      db.getOrders(active: active).then((rows) {
        final maps = rows
            .map((r) => jsonDecode(r.payload) as Map<String, dynamic>)
            .toList();
        controller.add(maps);
      }).catchError((e) {
        debugPrint('VendorCache cacheThrough seed error: $e');
        controller.add([]);
      });

      // 2. Bridge the live Supabase stream through the cache (cache-through).
      final sub = live.listen(
        (orders) async {
          try {
            await replaceOrders(orders);
          } catch (e) {
            debugPrint('VendorCache cacheThrough write error: $e');
          }
          final fresh = (await db.getOrders(active: active))
              .map((r) => jsonDecode(r.payload) as Map<String, dynamic>)
              .toList();
          controller.add(fresh);
        },
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  Future<void> replaceOrders(List<Map<String, dynamic>> orders) async {
    final db = _db;
    if (db == null) return;
    final rows = orders
        .where((o) =>
            activeOrderStatuses.contains(o['status']) ||
            historyOrderStatuses.contains(o['status']))
        .map(orderToCompanion)
        .toList();
    await db.replaceAllOrders(rows);
  }

  LocalVendorOrdersCompanion orderToCompanion(Map<String, dynamic> order) {
    final id = order['id']?.toString() ?? '';
    final created = DateTime.tryParse(order['order_time']?.toString() ?? '');
    return LocalVendorOrdersCompanion(
      id: Value(id),
      status: Value(order['status']?.toString() ?? ''),
      vendorId: Value(order['vendor_id']?.toString()),
      payload: Value(jsonEncode(order)),
      orderTime: Value(created),
      updatedAt: Value(DateTime.now()),
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile(String id) async {
    final db = _db;
    if (db == null) return null;
    final row = await db.getProfile(id);
    if (row == null) return null;
    return jsonDecode(row.payload) as Map<String, dynamic>;
  }

  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    final db = _db;
    final id = profile['id']?.toString();
    if (db == null || id == null) return;
    await db.upsertProfile(LocalVendorProfileCompanion(
      id: Value(id),
      payload: Value(jsonEncode(profile)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── Products ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.getProducts();
    return rows
        .map((r) => jsonDecode(r.payload) as Map<String, dynamic>)
        .toList();
  }

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final db = _db;
    if (db == null) return;
    final rows = products.map((p) {
      final id = p['id']?.toString() ?? '';
      return LocalProductCompanion(
        id: Value(id),
        vendorId: Value(p['vendor_id']?.toString()),
        name: Value(p['name']?.toString() ?? ''),
        price: Value((p['price'] as num?)?.toDouble()),
        payload: Value(jsonEncode(p)),
        updatedAt: Value(DateTime.now()),
      );
    }).toList();
    await db.replaceAllProducts(rows);
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getStats(String vendorId) async {
    final db = _db;
    if (db == null) return null;
    final row = await db.getStats(vendorId);
    if (row == null) return null;
    return {
      'todaySales': row.todaySales,
      'todayOrders': row.todayOrders,
    };
  }

  Future<void> cacheStats(String vendorId,
      {required double todaySales, required int todayOrders}) async {
    final db = _db;
    if (db == null) return;
    await db.upsertStats(LocalStatsCompanion(
      vendorId: Value(vendorId),
      todaySales: Value(todaySales),
      todayOrders: Value(todayOrders),
      updatedAt: Value(DateTime.now()),
    ));
  }
}