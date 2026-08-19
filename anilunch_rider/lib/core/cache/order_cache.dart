import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/order.dart';
import '../../models/rider.dart';
import '../database/app_database.dart';

// OrderCache is the cache-first read facade over Drift. Screens subscribe to
// its streams and render cached data instantly; the network refresh happens
// in the background and flows through the same streams.
class OrderCache {
  OrderCache._();
  static final OrderCache instance = OrderCache._();

  AppDatabase? _db;

  void init(AppDatabase db) {
    _db = db;
  }

  bool get isReady => _db != null;

  // ── Orders ────────────────────────────────────────────────────────────────
  Stream<List<OrderModel>> watchMyOrders(String riderId) {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db.watchRiderOrders(riderId).map(
        (rows) => rows.map(localOrderToModel).toList());
  }

  Future<List<OrderModel>> getMyOrders(String riderId) async {
    final db = _db;
    if (db == null) return [];
    final rows = await db.getRiderOrders(riderId);
    return rows.map(localOrderToModel).toList();
  }

  Future<void> cacheOrders(List<OrderModel> orders) async {
    final db = _db;
    if (db == null) return;
    await db.upsertOrders(orders.map(orderToCompanion).toList());
  }

  /// Reconciles the rider's whole feed against the server (authoritative).
  Future<void> replaceOrders(String riderId, List<OrderModel> orders) async {
    final db = _db;
    if (db == null) return;
    await db.replaceRiderOrders(riderId, orders.map(orderToCompanion).toList());
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<RiderModel?> getProfile(String riderId) async {
    final db = _db;
    if (db == null) return null;
    final row = await db.getRiderProfile(riderId);
    if (row == null) return null;
    return RiderModel.fromJson(jsonDecode(row.payload) as Map<String, dynamic>);
  }

  Future<void> cacheProfile(RiderModel rider) async {
    final db = _db;
    if (db == null) return;
    await db.upsertRiderProfile(LocalRiderProfileCompanion(
      id: Value(rider.id),
      payload: Value(jsonEncode(rider.toJson())),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ── Mappers ───────────────────────────────────────────────────────────────
  LocalOrdersCompanion orderToCompanion(OrderModel o) {
    return LocalOrdersCompanion(
      id: Value(o.id),
      status: Value(o.status),
      riderId: Value(o.riderId),
      customerName: Value(o.customerName),
      customerPhone: Value(o.customerPhone),
      customerAddress: Value(o.customerAddress),
      customerLat: Value(o.customerLat),
      customerLng: Value(o.customerLng),
      restaurantLat: Value(o.restaurantLat),
      restaurantLng: Value(o.restaurantLng),
      itemsJson: Value(jsonEncode(o.items)),
      totalAmount: Value(o.totalAmount),
      createdAt: Value(o.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  OrderModel localOrderToModel(LocalOrder row) {
    return OrderModel(
      id: row.id,
      status: row.status,
      riderId: row.riderId,
      customerName: row.customerName,
      customerPhone: row.customerPhone,
      customerAddress: row.customerAddress,
      customerLat: row.customerLat,
      customerLng: row.customerLng,
      restaurantLat: row.restaurantLat,
      restaurantLng: row.restaurantLng,
      items: jsonDecode(row.itemsJson) as List<dynamic>,
      totalAmount: row.totalAmount,
      createdAt: row.createdAt,
    );
  }
}