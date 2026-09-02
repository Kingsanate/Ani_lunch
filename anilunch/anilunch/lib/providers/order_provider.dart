import 'dart:async';

import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/providers/api_provider.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<WsEvent>? _wsSub;
  String? _subscribedUserId;
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

  void clearOrders() {
    _orders = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void addPlacedOrder(Map<String, dynamic> order) {
    final currentUserId = AniApi.currentUserId;
    if (order['user_id'] != null && currentUserId != null && order['user_id'] != currentUserId) {
      return;
    }
    final existingIndex = _orders.indexWhere((o) => o['id'] == order['id']);
    if (existingIndex >= 0) {
      _orders[existingIndex] = order;
    } else {
      _orders.insert(0, order);
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _sortOrders(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final tA = DateTime.tryParse(a['order_time']?.toString() ?? a['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tB = DateTime.tryParse(b['order_time']?.toString() ?? b['created_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tB.compareTo(tA);
    });
    return list;
  }

  Future<void> fetchOrders(String userId, {required bool isLunchMode}) async {
    _error = null;

    if (userId.isEmpty || userId == 'guest-user') {
      _orders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final serverOrders = await AniApi.instance.api.orders.list(
        orderType: isLunchMode ? 'lunch' : 'meat',
      );
      _orders = _sortOrders(serverOrders
          .where((o) => o.userId == userId || o.userId.isEmpty)
          .map(_toDisplayMap)
          .toList());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch user orders error: $e');
      _isLoading = false;
      notifyListeners();
    }
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
    if (userId.isEmpty || userId == 'guest-user') return;
    if (_subscribedUserId == userId && _wsSub != null) return;
    _subscribedUserId = userId;

    // Realtime WebSocket channel for user orders
    try {
      final realtime = AniApi.instance.realtime;
      realtime.connect().then((_) {
        for (final order in _orders) {
          realtime.join('order:${order['id']}');
        }
      }).catchError((_) {});
      _wsSub?.cancel();
      _wsSub = realtime.events.listen((event) {
        final orderEvent = event.orderEvent;
        if (orderEvent == null) return;
        fetchOrders(userId, isLunchMode: isLunchMode);
      });
    } catch (e) {
      _error = e.toString();
    }
  }

  // Maps a core Order into the legacy map shape consumed by the UI.
  static Map<String, dynamic> _toDisplayMap(Order o) {
    final address = [
      if (o.deliveryStreet.isNotEmpty) o.deliveryStreet,
      if (o.deliveryCity.isNotEmpty) o.deliveryCity,
      if (o.deliveryZip.isNotEmpty) o.deliveryZip,
    ].join(', ');

    final items = o.items.isNotEmpty
        ? o.items
            .map((i) {
              final resolvedPrice = i.price > 0 ? i.price : (i.unitPrice.paise ~/ 100);
              return {
                'id': i.id.isNotEmpty ? i.id : i.itemId,
                'title': i.name,
                'name': i.name,
                'price': resolvedPrice > 0 ? resolvedPrice : 200,
                'unit_price': resolvedPrice > 0 ? resolvedPrice : 200,
                'quantity': i.quantity > 0 ? i.quantity : 1,
                'qty': i.quantity > 0 ? i.quantity : 1,
                'image': i.image,
              };
            })
            .toList()
        : [
            {
              'id': 'meal-1',
              'title': 'Signature Lunch Thali',
              'name': 'Signature Lunch Thali',
              'price': (o.subtotal.paise ~/ 100) > 0 ? (o.subtotal.paise ~/ 100) : 200,
              'unit_price': (o.subtotal.paise ~/ 100) > 0 ? (o.subtotal.paise ~/ 100) : 200,
              'quantity': 1,
              'qty': 1,
              'image': 'assets/images/bento.png',
            }
          ];

    final subtotal = o.subtotal.paise > 0
        ? o.subtotal.paise ~/ 100
        : (o.totalAmount.paise ~/ 100 > 30 ? (o.totalAmount.paise ~/ 100) - 30 : 200);
    final deliveryFee = o.deliveryFee.paise > 0 ? o.deliveryFee.paise ~/ 100 : 30;
    final totalAmount = o.totalAmount.paise > 0
        ? o.totalAmount.paise ~/ 100
        : (subtotal + deliveryFee);

    return {
      'id': o.id,
      'user_id': o.userId,
      'order_type': o.orderType,
      'status': o.status,
      'items': items,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount_amount': o.discount.paise ~/ 100,
      'total_amount': totalAmount,
      'total': totalAmount,
      'payment_method': o.paymentMethod.toLowerCase() == 'cod' ? 'COD' : 'Online',
      'payment_status': o.paymentStatus,
      'address': address.isNotEmpty ? address : 'NIFT Mawlai Umsawli Shillong',
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