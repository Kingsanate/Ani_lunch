import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/foundation.dart';
import '../core/providers/api_provider.dart';
import 'api_client.dart';

class AdminProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _riders = [];
  List<Map<String, dynamic>> _menuItems = [];
  List<Map<String, dynamic>> _dailyDeals = [];
  final bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get riders => _riders;
  List<Map<String, dynamic>> get menuItems => _menuItems;
  List<Map<String, dynamic>> get dailyDeals => _dailyDeals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<WsEvent>? _wsSub;

  Future<void> fetchAllOrders() async {
    try {
      _orders = await ApiClient.fetchOrders();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllRiders() async {
    try {
      _riders = await ApiClient.fetchRiders();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllMenuItems() async {
    try {
      _menuItems = await ApiClient.fetchItems();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllDailyDeals() async {
    try {
      _dailyDeals = await ApiClient.fetchDeals();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await ApiClient.transitionOrder(orderId, status);
      await fetchAllOrders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> approveRider(String riderId) async {
    try {
      await ApiClient.setRiderApproval(riderId, 'approved');
      await fetchAllRiders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    try {
      await ApiClient.saveItem(data);
      await fetchAllMenuItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data)..['id'] = id;
      await ApiClient.saveItem(payload);
      await fetchAllMenuItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await ApiClient.deleteItem(id);
      await fetchAllMenuItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addDailyDeal(Map<String, dynamic> data) async {
    try {
      await ApiClient.saveDeal(data);
      await fetchAllDailyDeals();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateDailyDeal(String id, Map<String, dynamic> data) async {
    try {
      final parsedId = int.tryParse(id);
      final payload = Map<String, dynamic>.from(data)..['id'] = parsedId ?? id;
      await ApiClient.saveDeal(payload);
      await fetchAllDailyDeals();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDailyDeal(String id) async {
    try {
      final parsedId = int.tryParse(id) ?? 0;
      await ApiClient.deleteDeal(parsedId);
      await fetchAllDailyDeals();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void subscribeToRealtime() {
    final realtime = AniApi.instance.realtime;
    if (!realtime.isConnected) return;

    realtime.join('admin.orders');
    _wsSub = realtime.events.listen((event) {
      fetchAllOrders();
      fetchAllRiders();
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}
