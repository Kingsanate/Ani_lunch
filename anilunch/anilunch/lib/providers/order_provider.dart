import 'dart:async';

import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/api_provider.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<WsEvent>? _wsSub;
  double? _customerLat;
  double? _customerLng;

  List<Map<String, dynamic>> get orders => _orders;

  List<Map<String, dynamic>> get todayOrders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <Map<String, dynamic>>[];
    for (final order in _orders) {
      final orderDate = _parseOrderDate(order);
      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
      if (orderDay.isAtSameMomentAs(today)) {
        result.add(order);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> get pastOrders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <Map<String, dynamic>>[];
    for (final order in _orders) {
      final orderDate = _parseOrderDate(order);
      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
      if (!orderDay.isAtSameMomentAs(today)) {
        result.add(order);
      }
    }
    return result;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get customerLat => _customerLat;
  double? get customerLng => _customerLng;

  DateTime _parseOrderDate(Map<String, dynamic> order) {
    try {
      final rawDate = order['order_time'] ?? order['created_at'] ?? order['date'];
      if (rawDate is DateTime) return rawDate;
      if (rawDate is String) return DateTime.parse(rawDate);
    } catch (_) {}
    return DateTime.now();
  }

  void addPlacedOrder(Map<String, dynamic> order) {
    final existingIndex = _orders.indexWhere((o) => o['id'] == order['id']);
    if (existingIndex >= 0) {
      _orders[existingIndex] = order;
    } else {
      _orders.insert(0, order);
    }
    notifyListeners();
  }

  Future<void> fetchOrders(String userId, {required bool isLunchMode}) async {
    _error = null;

    // 1. Try Go backend API
    try {
      final serverOrders = await AniApi.instance.api.orders.list(
        orderType: isLunchMode ? 'lunch' : 'meat',
      );
      if (serverOrders.isNotEmpty) {
        _orders = serverOrders.map(_toDisplayMap).toList();
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (_) {}

    // 2. Try Supabase direct query
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      if (data.isNotEmpty) {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await AniApi.instance.api.orders.cancel(orderId);

      final index = _orders.indexWhere((o) => o['id'].toString() == orderId);
      if (index >= 0) {
        _orders[index]['status'] = 'cancelled';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> captureLocation() async {
    try {
      final status = await Geolocator.requestPermission();
      if (status == LocationPermission.denied) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _customerLat = position.latitude;
      _customerLng = position.longitude;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void subscribeToUpdates(String userId, {required bool isLunchMode}) {
    try {
      final realtime = AniApi.instance.realtime;
      if (realtime.isConnected) {
        for (final order in _orders) {
          realtime.join('order:${order['id']}');
        }
      }
      _wsSub ??= realtime.events.listen((event) {
        final orderEvent = event.orderEvent;
        if (orderEvent == null) return;
        if (orderEvent.userId != null && orderEvent.userId != userId) return;
        fetchOrders(userId, isLunchMode: isLunchMode);
      });
    } catch (e) {
      _error = e.toString();
    }
  }

  // Maps a core Order into the legacy map shape consumed by the UI. Money is
  // converted from paise to rupee ints for display.
  static Map<String, dynamic> _toDisplayMap(Order o) {
    final address = [
      if (o.deliveryStreet.isNotEmpty) o.deliveryStreet,
      if (o.deliveryCity.isNotEmpty) o.deliveryCity,
      if (o.deliveryZip.isNotEmpty) o.deliveryZip,
    ].join(', ');
    return {
      'id': o.id,
      'user_id': o.userId,
      'order_type': o.orderType,
      'status': o.status,
      'items': o.items
          .map((i) => {
                'id': i.id,
                'title': i.name,
                'name': i.name,
                'price': i.price,
                'unit_price': i.price,
                'quantity': i.quantity,
                'image': i.image,
              })
          .toList(),
      'subtotal': o.subtotal.paise ~/ 100,
      'delivery_fee': o.deliveryFee.paise ~/ 100,
      'discount_amount': o.discount.paise ~/ 100,
      'total_amount': o.totalAmount.paise ~/ 100,
      'total': o.totalAmount.paise ~/ 100,
      'payment_method': o.paymentMethod == 'cod' ? 'COD' : 'Online',
      'payment_status': o.paymentStatus,
      'address': address,
      'order_time': o.createdAt.toIso8601String(),
      'created_at': o.createdAt.toIso8601String(),
      'date': o.createdAt.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}