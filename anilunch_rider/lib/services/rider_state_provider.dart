import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/foundation.dart';
import '../models/rider.dart';
import '../models/order.dart';
import 'order_service.dart';
import 'order_accept_service.dart';
import 'rider_service.dart';
import 'auth_service.dart';

class RiderStateProvider extends ChangeNotifier {
  RiderModel? _rider;
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _myOrders = [];
  OrderModel? _activeOrder;
  bool _isOnline = false;
  bool _isLoading = false;
  String? _error;

  StreamSubscription<WsEvent>? _realtimeSub;
  void Function(OrderModel)? _onBroadcastOrder;
  void Function(OrderModel)? _onAssignedOrder;

  RiderModel? get rider => _rider;
  List<OrderModel> get availableOrders => _availableOrders;
  List<OrderModel> get myOrders => _myOrders;
  OrderModel? get activeOrder => _activeOrder;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rider = await AuthService.loadRiderProfile();
      if (_rider != null) {
        _isOnline = _rider!.isOnline;
        _availableOrders = await OrderService.fetchAvailableOrders(_rider!.id);
        _myOrders = await OrderService.fetchMyOrders(_rider!.id);
        _activeOrder = await OrderService.fetchActiveOrder(_rider!.id);
        subscribeToOrders();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleOnlineStatus() async {
    if (_rider == null) return;
    final newStatus = !_isOnline;
    try {
      await RiderService.setOnlineStatus(_rider!.id, newStatus);
      _isOnline = newStatus;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    if (_rider == null) return false;
    final success = await OrderAcceptService.acceptOrder(orderId);
    if (success && _rider != null) {
      _activeOrder = await OrderService.fetchActiveOrder(_rider!.id);
      notifyListeners();
    }
    return success;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await OrderService.updateStatus(orderId, status);
    if (_rider != null) {
      _activeOrder = await OrderService.fetchActiveOrder(_rider!.id);
      notifyListeners();
    }
  }

  // ── Realtime: riders.available broadcast + rider:{id} channel ─────────────
  void subscribeToOrders() {
    if (_rider == null) return;

    _realtimeSub?.cancel();
    _realtimeSub = OrderService.subscribeToRealtime(
      riderId: _rider!.id,
      onBroadcastOrder: (order) => _onBroadcastOrder?.call(order),
      onAssignedOrder: (order) => _onAssignedOrder?.call(order),
      onAvailableUpdated: (orders) {
        _availableOrders = orders;
        notifyListeners();
      },
    );
  }

  // ── Broadcast: fires when ANY order becomes ready_for_pickup ──────────────
  // All online riders receive the notification; first to accept wins.
  void subscribeToReadyForPickupOrders({
    required void Function(OrderModel) onNewOrder,
  }) {
    _onBroadcastOrder = onNewOrder;
    if (_realtimeSub == null) subscribeToOrders();
  }

  // ── Legacy: fires for orders directly assigned to this rider ──────────────
  void subscribeToNewOrders({
    required void Function(OrderModel) onNewOrder,
  }) {
    _onAssignedOrder = onNewOrder;
    if (_realtimeSub == null) subscribeToOrders();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}