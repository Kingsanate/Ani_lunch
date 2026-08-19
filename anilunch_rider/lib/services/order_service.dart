import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/api_provider.dart';
import '../models/order.dart';
import 'api_client.dart';
import 'order_accept_service.dart';

class OrderService {
  static final _supabase = Supabase.instance.client;

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
        if (status == 'accepted' || status == 'picked_up') {
          return _toOrderModel(o);
        }
      }
      return null;
    } catch (e) {
      debugPrint('fetchActiveOrder error: $e');
      return null;
    }
  }

  // ── Accept an order atomically via the Go backend ─────────────────────────
  static Future<bool> acceptOrder(String orderId) async {
    return OrderAcceptService.acceptOrder(orderId);
  }

  // ── Update order status ───────────────────────────────────────────────────
  static Future<void> updateStatus(String orderId, String status) async {
    // 1. Try the Go backend (server-authoritative transition).
    if (await ApiClient.transitionOrder(orderId, status)) {
      return;
    }

    // 2. Fallback: direct Supabase update.
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      debugPrint('updateStatus error: $e');
    }
  }

  // ── Realtime via the Go gateway ───────────────────────────────────────────
  // Subscribes to the riders.available broadcast; refetches the available
  // list on every order event. Returns a subscription to cancel on dispose.
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

  // Joins the riders.available broadcast + the rider:{id} channel, then
  // routes order events to the caller. Events carry only a status summary,
  // so full order payloads are refetched from the API before callbacks fire.
  static StreamSubscription<WsEvent> subscribeToRealtime({
    required String riderId,
    required void Function(OrderModel) onBroadcastOrder,
    required void Function(OrderModel) onAssignedOrder,
    required void Function(List<OrderModel>) onAvailableUpdated,
  }) {
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) {
      return const Stream<WsEvent>.empty().listen((_) {});
    }

    realtime.join('riders.available');
    realtime.join('rider:$riderId');

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
  static OrderModel _toOrderModel(RiderOrder o) => OrderModel(
        id: o.id,
        status: o.status,
        customerName: o.customerName.isNotEmpty ? o.customerName : null,
        customerPhone: o.customerPhone.isNotEmpty ? o.customerPhone : null,
        customerAddress: o.address,
        customerLat: o.latitude,
        customerLng: o.longitude,
        items: o.items
            .map((i) => {
                  'name': i.name,
                  'quantity': i.quantity,
                  'price': i.unitPrice.paise ~/ 100,
                })
            .toList(),
        totalAmount: o.totalAmount.paise / 100,
        createdAt: o.orderTime,
      );
}