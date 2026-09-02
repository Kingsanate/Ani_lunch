import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/foundation.dart';
import '../core/providers/api_provider.dart';
import '../models/order.dart';
import 'order_accept_service.dart';

class OrderService {
  // ── Fetch unassigned orders ready for pickup ──────────────────────────────
  static Future<List<OrderModel>> fetchAvailableOrders(String riderId) async {
    try {
      final orders = await AniApi.instance.api.riders.availableOrders();
      final models = orders.map(_toOrderModel).toList()
        ..sort((a, b) {
          final ta = a.createdAt;
          final tb = b.createdAt;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });
      return models;
    } catch (e) {
      debugPrint('fetchAvailableOrders error: $e');
      return [];
    }
  }

  // ── Fetch all orders assigned to this rider ───────────────────────────────
  static Future<List<OrderModel>> fetchMyOrders(String riderId) async {
    try {
      final orders = await AniApi.instance.api.riders.myOrders();
      final models = orders.map(_toOrderModel).toList()
        ..sort((a, b) {
          final ta = a.createdAt;
          final tb = b.createdAt;
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta);
        });
      return models;
    } catch (e) {
      debugPrint('fetchMyOrders error: $e');
      return [];
    }
  }

  // ── Active order for this rider (in-progress) ─────────────────────────────
  static Future<OrderModel?> fetchActiveOrder(String riderId) async {
    try {
      final orders = await AniApi.instance.api.riders.myOrders();
      for (final o in orders) {
        final status = o.status.toLowerCase();
        if (status == 'accepted' || status == 'picked_up' || status == 'out_for_delivery') {
          return _toOrderModel(o);
        }
      }
    } catch (e) {
      debugPrint('fetchActiveOrder error: $e');
    }
    return null;
  }

  // ── Accept an order atomically via the Go backend ─────────────────────────
  static Future<bool> acceptOrder(String orderId) async {
    return OrderAcceptService.acceptOrder(orderId);
  }

  // ── Update order status ───────────────────────────────────────────────────
  static Future<void> updateStatus(String orderId, String status) async {
    try {
      await AniApi.instance.api.orders.transition(orderId, status);
    } catch (e) {
      debugPrint('updateStatus error: $e');
    }
  }

  // ── Realtime via Go Gateway ─────────────────────────────
  static StreamSubscription<WsEvent> subscribeToAvailableOrders({
    required void Function(List<OrderModel>) onUpdate,
    required String riderId,
  }) {
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) {
      return const Stream<WsEvent>.empty().listen((_) {});
    }
    realtime.join('riders.available');
    return realtime.events.listen((event) async {
      if (event.orderEvent == null) return;
      onUpdate(await fetchAvailableOrders(riderId));
    });
  }

  static StreamSubscription<WsEvent> subscribeToRealtime({
    required String riderId,
    required void Function(OrderModel) onBroadcastOrder,
    required void Function(OrderModel) onAssignedOrder,
    required void Function(List<OrderModel>) onAvailableUpdated,
  }) {
    final realtime = AniApi.instance.realtime;
    realtime.connect().then((_) {
      realtime.join('riders.available');
      realtime.join('rider:$riderId');
    }).catchError((_) {});

    return realtime.events.listen((event) async {
      final orderEvent = event.orderEvent;
      if (orderEvent == null) return;
      try {
        final status = orderEvent.status.toLowerCase();
        final assignedToMe =
            orderEvent.riderId != null && orderEvent.riderId == riderId;

        if (status == 'ready_for_pickup' && !assignedToMe) {
          final available = await fetchAvailableOrders(riderId);
          onAvailableUpdated(available);
          final order = _findById(available, orderEvent.orderId);
          if (order != null) onBroadcastOrder(order);
        } else if (status == 'assigned' && assignedToMe) {
          final mine = await fetchMyOrders(riderId);
          final order = _findById(mine, orderEvent.orderId);
          if (order != null) onAssignedOrder(order);
        } else {
          onAvailableUpdated(await fetchAvailableOrders(riderId));
        }
      } catch (e) {
        debugPrint('subscribeToRealtime event error: $e');
      }
    });
  }

  static OrderModel? _findById(List<OrderModel> orders, String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  // Maps a core RiderOrder into the local OrderModel shape consumed by the UI.
  static OrderModel _toOrderModel(RiderOrder o) {
    final subtotal = o.subtotal.paise > 0
        ? o.subtotal.paise / 100
        : (o.items.isNotEmpty
            ? o.items.fold<double>(0.0, (acc, item) => acc + (item.unitPrice.paise / 100) * item.quantity)
            : 200.0);
    final deliveryFee = o.deliveryFee.paise > 0 ? o.deliveryFee.paise / 100 : 30.0;
    final totalAmount = o.totalAmount.paise > 0 ? o.totalAmount.paise / 100 : (subtotal + deliveryFee);

    final mappedItems = o.items.isNotEmpty
        ? o.items
            .map((i) => {
                  'name': i.name,
                  'title': i.name,
                  'quantity': i.quantity > 0 ? i.quantity : 1,
                  'qty': i.quantity > 0 ? i.quantity : 1,
                  'price': i.unitPrice.paise ~/ 100 > 0 ? i.unitPrice.paise ~/ 100 : 200,
                  'unit_price': i.unitPrice.paise ~/ 100 > 0 ? i.unitPrice.paise ~/ 100 : 200,
                  'image': i.image,
                  'customizations': i.customizations,
                })
            .toList()
        : [
            {
              'name': 'Signature Lunch Thali',
              'title': 'Signature Lunch Thali',
              'quantity': 1,
              'qty': 1,
              'price': subtotal.toInt(),
              'unit_price': subtotal.toInt(),
              'image': 'assets/images/bento.png',
            }
          ];

    return OrderModel(
      id: o.id,
      status: o.status,
      customerName: o.customerName.isNotEmpty ? o.customerName : 'Customer',
      customerPhone: o.customerPhone.isNotEmpty ? o.customerPhone : null,
      customerAddress: o.address.isNotEmpty ? o.address : 'NIFT Mawlai Umsawli Shillong',
      customerLat: o.latitude,
      customerLng: o.longitude,
      items: mappedItems,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      createdAt: o.orderTime,
    );
  }
}