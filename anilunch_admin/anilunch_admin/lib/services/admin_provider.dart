import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

class AdminProvider extends ChangeNotifier {
  static final _supabase = Supabase.instance.client;

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

  RealtimeChannel? _ordersChannel;
  RealtimeChannel? _ridersChannel;
  RealtimeChannel? _menuChannel;
  RealtimeChannel? _dealsChannel;

  Future<void> fetchAllOrders() async {
    try {
      final data = await _supabase.from('orders').select();
      _orders = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllRiders() async {
    try {
      final data = await _supabase
          .from('riders')
          .select()
          .order('created_at', ascending: false);
      _riders = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllMenuItems() async {
    try {
      final data = await _supabase
          .from('items')
          .select('*, menus(menu_title)')
          .order('item_title');
      _menuItems = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllDailyDeals() async {
    try {
      final data = await _supabase
          .from('daily_deals')
          .select()
          .order('created_at');
      _dailyDeals = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      // 1. Try the Go backend (server-authoritative transition).
      if (!await ApiClient.transitionOrder(orderId, status)) {
        // 2. Fallback: direct Supabase update.
        await _supabase
            .from('orders')
            .update({'status': status})
            .eq('id', orderId);
      }
      await fetchAllOrders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> approveRider(String riderId) async {
    try {
      // 1. Try the Go backend (server-authoritative approval).
      if (!await ApiClient.setRiderApproval(riderId, 'approved')) {
        // 2. Fallback: direct Supabase update.
        await _supabase.from('riders').update({
          'is_approved': true,
          'approval_status': 'approved',
          'rejection_reason': null,
        }).eq('id', riderId);
      }
      await fetchAllRiders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addMenuItem(Map<String, dynamic> data) async {
    try {
      await _supabase.from('items').insert(data);
      await fetchAllMenuItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('items').update(data).eq('id', id);
      await fetchAllMenuItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      await _supabase.from('items').delete().eq('id', id);
      await fetchAllMenuItems();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addDailyDeal(Map<String, dynamic> data) async {
    try {
      await _supabase.from('daily_deals').insert(data);
      await fetchAllDailyDeals();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateDailyDeal(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('daily_deals').update(data).eq('id', id);
      await fetchAllDailyDeals();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDailyDeal(String id) async {
    try {
      await _supabase.from('daily_deals').delete().eq('id', id);
      await fetchAllDailyDeals();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void subscribeToRealtime() {
    _ordersChannel?.unsubscribe();
    _ordersChannel = _supabase
        .channel('public:admin_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => fetchAllOrders(),
        )
        .subscribe();

    _ridersChannel?.unsubscribe();
    _ridersChannel = _supabase
        .channel('public:admin_riders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'riders',
          callback: (_) => fetchAllRiders(),
        )
        .subscribe();

    _menuChannel?.unsubscribe();
    _menuChannel = _supabase
        .channel('public:admin_menu')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (_) => fetchAllMenuItems(),
        )
        .subscribe();

    _dealsChannel?.unsubscribe();
    _dealsChannel = _supabase
        .channel('public:admin_deals')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_deals',
          callback: (_) => fetchAllDailyDeals(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    _ridersChannel?.unsubscribe();
    _menuChannel?.unsubscribe();
    _dealsChannel?.unsubscribe();
    super.dispose();
  }
}
