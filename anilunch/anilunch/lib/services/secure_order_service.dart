import 'dart:convert';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/providers/api_provider.dart';

class SecureOrderService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  static SecureOrderService? _instance;

  // Shared instance for checkout flows; base URL overridable in tests.
  static SecureOrderService get instance => _instance ??= SecureOrderService(
        db: AppDatabase(),
      );

  static void overrideForTesting(SecureOrderService service) => _instance = service;

  SecureOrderService({
    required AppDatabase db,
  }) : _db = db;

  // PlaceOrder creates an order with client-side idempotency and server-side
  // authoritative pricing via the Go API. On network failure the order is
  // persisted as a local Drift draft and replayed by the SyncEngine.
  Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
    String paymentMethod = 'cod',
    String orderType = 'meat',
    String? couponCode,
    String deliveryStreet = '',
    String deliveryCity = '',
    String deliveryZip = '',
    double? deliveryLat,
    double? deliveryLng,
    String? specialNotes,
  }) async {
    final idempotencyKey = _uuid.v4();
    final normalizedPayment = paymentMethod.toLowerCase() == 'cod' ? 'cod' : 'online';

    final orderPayload = {
      'idempotency_key': idempotencyKey,
      'order_type': orderType,
      'payment_method': normalizedPayment,
      'coupon_code': couponCode,
      'delivery_street': deliveryStreet,
      'delivery_city': deliveryCity,
      'delivery_zip': deliveryZip,
      'delivery_lat': ?deliveryLat,
      'delivery_lng': ?deliveryLng,
      'special_notes': specialNotes,
      'items': cartItems.map((item) {
        final customizations = item['customizations'];
        return {
          'item_id': item['item_id'],
          'quantity': item['quantity'],
          if (customizations is Map && customizations.isNotEmpty)
            'customizations': customizations,
        };
      }).toList(),
    };

    try {
      final order = await AniApi.instance.api.orders.create(CreateOrderRequest(
        idempotencyKey: idempotencyKey,
        orderType: orderType,
        paymentMethod: normalizedPayment,
        couponCode: couponCode,
        deliveryStreet: deliveryStreet,
        deliveryCity: deliveryCity,
        deliveryZip: deliveryZip,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        specialNotes: specialNotes,
        items: cartItems
            .map((item) => OrderItemRequest(
                  itemId: item['item_id'].toString(),
                  quantity: (item['quantity'] as num?)?.toInt() ?? 1,
                  customizations: (item['customizations'] is Map<String, dynamic>)
                      ? Map<String, String>.from(item['customizations'] as Map)
                      : null,
                ))
            .toList(),
      ));

      // Clear local cart upon successful placement
      await _db.clearCart();

      return {
        'success': true,
        'order': order,
        'idempotency_key': idempotencyKey,
      };
    } catch (e) {
      debugPrint('Online order placement failed, falling back to local offline draft: $e');
    }

    // 2. Offline fallback: Persist in local Drift SQLite & enqueue in SyncQueue.
    //    Fees mirror the server rule (₹30, free above ₹500) — the server
    //    recomputes authoritatively on replay.
    final localOrderId = 'LOCAL-${_uuid.v4()}';
    int calculatedSubtotalPaise = 0;
    for (final item in cartItems) {
      final price = (item['price'] as num?)?.toInt() ?? 0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      calculatedSubtotalPaise += price * qty;
    }
    final estimatedDeliveryFeePaise = calculatedSubtotalPaise >= 50000 ? 0 : 3000;

    final localOrderCompanion = LocalOrdersCompanion(
      id: Value(localOrderId),
      userId: Value(userId),
      status: const Value('pending'),
      subtotal: Value(BigInt.from(calculatedSubtotalPaise)),
      deliveryFee: Value(BigInt.from(estimatedDeliveryFeePaise)),
      discount: Value(BigInt.zero),
      totalAmount: Value(BigInt.from(calculatedSubtotalPaise + estimatedDeliveryFeePaise)),
      couponCode: Value(couponCode),
      paymentMethod: Value(normalizedPayment),
      paymentStatus: const Value('pending'),
      deliveryStreet: Value(deliveryStreet),
      deliveryCity: Value(deliveryCity),
      deliveryZip: Value(deliveryZip),
      specialNotes: Value(specialNotes),
      idempotencyKey: Value(idempotencyKey),
      syncStatus: const Value('pending'),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _db.insertLocalOrder(localOrderCompanion);

      // Enqueue mutation for background sync
      await _db.enqueueSyncTask(SyncQueueCompanion(
        id: Value(_uuid.v4()),
        entityType: const Value('order'),
        entityId: Value(localOrderId),
        action: const Value('create'),
        payload: Value(jsonEncode(orderPayload)),
        idempotencyKey: Value(idempotencyKey),
        status: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      // Clear local cart
      await _db.clearCart();
    } catch (driftErr) {
      debugPrint('Local Drift offline storage notice: $driftErr');
    }

    return {
      'success': true,
      'is_offline_draft': true,
      'order_id': localOrderId,
      'idempotency_key': idempotencyKey,
    };
  }
}