import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cache/vendor_cache.dart';
import '../core/providers/api_provider.dart';
import 'api_client.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static const activeStatuses = [
    'pending',
    'confirmed',
    'preparing',
    'ready_for_pickup',
    'assigned',
    'accepted',
    'picked_up',
  ];
  static const historyStatuses = [
    'completed',
    'cancelled',
    'refunded',
    'delivered',
  ];

  // ---------------------------------------------------------
  // Vendor Profile (cache-first with background refresh)
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>?> getVendorProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    // Cache-first: render instantly on cold start, refresh in background.
    final cached = await VendorCache.instance.getProfile(user.id);
    if (cached != null) {
      refreshVendorProfile(user.id);
      return cached;
    }

    final fresh = await _fetchVendorProfile();
    return fresh;
  }

  static Future<Map<String, dynamic>?> _fetchVendorProfile() async {
    // 1. Try the Go backend (authoritative vendor profile).
    try {
      final v = await AniApi.instance.api.vendors.me();
      final map = <String, dynamic>{
        'id': v.id,
        'name': v.name,
        'address': v.address,
        'phone': v.phone,
        'is_open': v.isOpen,
      };
      await VendorCache.instance.cacheProfile(map);
      return map;
    } catch (e) {
      debugPrint('Error fetching vendor profile via API: $e');
    }

    // 2. Fallback: Supabase sellers row.
    try {
      final res = await client
          .from('sellers')
          .select()
          .eq('id', client.auth.currentUser!.id)
          .maybeSingle();
      if (res != null) {
        await VendorCache.instance.cacheProfile(res);
      }
      return res;
    } catch (e) {
      debugPrint('Error fetching vendor profile: $e');
      return null;
    }
  }

  static Future<void> refreshVendorProfile(String userId) async {
    final fresh = await _fetchVendorProfile();
    if (fresh != null) {
      await VendorCache.instance.cacheProfile(fresh);
    }
  }

  // ---------------------------------------------------------
  // Dashboard & Wallet
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> getDashboardStats(String vendorId) async {
    // Cache-first: show yesterday's snapshot instantly, refresh in background.
    final cached = await VendorCache.instance.getStats(vendorId);
    if (cached != null) return cached;

    try {
      final stats = await AniApi.instance.api.vendors.stats();
      return {
        'todaySales': stats.revenueToday.paise / 100,
        'todayOrders': stats.ordersToday,
      };
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return {'todaySales': 0.0, 'todayOrders': 0};
    }
  }

  static Future<void> cacheDashboardStats(String vendorId,
      {required double todaySales, required int todayOrders}) {
    return VendorCache.instance.cacheStats(vendorId,
        todaySales: todaySales, todayOrders: todayOrders);
  }

  static Future<double> getTotalSales(String vendorId) async {
    try {
      final stats = await AniApi.instance.api.vendors.stats();
      return stats.revenueToday.paise / 100;
    } catch (e) {
      debugPrint('Error fetching total sales: $e');
      return 0.0;
    }
  }

  // ---------------------------------------------------------
  // Menu / Products (cache-first)
  // ---------------------------------------------------------
  static Future<List<dynamic>> getVendorProducts(String vendorId) async {
    try {
      final items = await AniApi.instance.api.catalog.items();
      final legacy = items.map((i) => <String, dynamic>{
        'id': i.id,
        'name': i.name,
        'item_price': i.price.paise / 100,
        'thumbnail_url': i.imageUrl,
        'is_available': i.isAvailable,
      }).toList();
      await VendorCache.instance
          .cacheProducts(legacy.cast<Map<String, dynamic>>());
      return legacy;
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }

    try {
      final res =
          await client.from('meal_products').select().order('name');
      await VendorCache.instance.cacheProducts(res.cast<Map<String, dynamic>>());
      return res;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return VendorCache.instance.getProducts();
    }
  }

  // ---------------------------------------------------------
  // Orders — Active/History Streams (cache-through)
  // Live source = WS vendor:{id} events refetching /api/v1/vendors/me/orders.
  // A single shared underlying stream is ref-counted across views so the WS
  // join and the 30s safety-net poll run at most once per vendor.
  // ---------------------------------------------------------
  static Stream<List<Map<String, dynamic>>> activeOrdersStream(String vendorId) {
    return _sharedOrdersStream(vendorId).map(
        (orders) => orders.where((o) => activeStatuses.contains(o['status'])).toList());
  }

  static Stream<List<Map<String, dynamic>>> historyOrdersStream(String vendorId) {
    return _sharedOrdersStream(vendorId).map(
        (orders) => orders.where((o) => historyStatuses.contains(o['status'])).toList());
  }

  static Stream<List<Map<String, dynamic>>> _sharedOrdersStream(
    String vendorId,
  ) {
    final controller =
        StreamController<List<Map<String, dynamic>>>.broadcast();
    StreamSubscription<WsEvent>? wsSub;
    Timer? pollTimer;
    var realtimeJoined = false;
    var listeners = 0;
    var disposed = false;

    Future<void> fetch() async {
      if (disposed) return;
      try {
        final orders = await AniApi.instance.api.vendors.orders();
        if (disposed) return;
        controller.add(orders.map(_toLegacyOrder).toList());
      } catch (e) {
        debugPrint('Vendor orders fetch error: $e');
      }
    }

    void start() {
      fetch();

      try {
        final realtime = AniApi.instance.realtime;
        if (realtime.isConnected) {
          realtime.join('vendor:$vendorId');
          realtimeJoined = true;
          wsSub = realtime.events.listen((event) {
            final orderEvent = event.orderEvent;
            if (orderEvent == null) return;
            if (orderEvent.vendorId != null &&
                orderEvent.vendorId != vendorId) {
              return;
            }
            fetch();
          });
        }
      } catch (e) {
        debugPrint('Vendor WS subscribe error: $e');
      }

      // Safety net: re-sync every 30s in case a WS event is missed.
      pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
    }

    void dispose() {
      disposed = true;
      wsSub?.cancel();
      pollTimer?.cancel();
      if (realtimeJoined) {
        try {
          AniApi.instance.realtime.leave('vendor:$vendorId');
        } catch (_) {}
      }
      controller.close();
    }

    controller.onListen = () {
      listeners++;
      if (listeners == 1) start();
      // Fresh data for a newly subscribed view; the shared poll/WS stay single.
      fetch();
    };
    controller.onCancel = () {
      listeners--;
      if (listeners == 0) dispose();
    };

    return controller.stream;
  }

  static Map<String, dynamic> _toLegacyOrder(VendorOrder o) => {
        'id': o.id,
        'order_time': o.orderTime.toIso8601String(),
        'status': o.status,
        'ordered_by':
            o.customerName.isNotEmpty ? o.customerName : 'Customer',
        'items': o.items
            .map((i) => {
                  'qty': i.quantity,
                  'name': i.name,
                  'price': i.unitPrice.paise / 100,
                })
            .toList(),
        'total_amount': o.totalAmount.paise / 100,
        'address': o.address,
      };

  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // 1. Try the Go backend (server-authoritative transition).
    if (await ApiClient.transitionOrder(orderId, newStatus)) {
      return;
    }

    // 2. Fallback: direct Supabase update.
    await client.from('orders').update({'status': newStatus}).eq('id', orderId);
  }

  // ---------------------------------------------------------
  // Profile
  // ---------------------------------------------------------
  static Future<void> toggleStoreStatus(String vendorId, bool isOpen) async {
    try {
      await AniApi.instance.api.vendors.updateProfile(isOpen: isOpen);
      return;
    } catch (e) {
      debugPrint('toggleStoreStatus via API error: $e');
    }
    try {
      await client
          .from('sellers')
          .update({'is_open': isOpen})
          .eq('id', vendorId);
    } catch (e) {
      debugPrint('toggleStoreStatus error: $e');
    }
  }

  static Future<void> logout() async {
    await AniApi.exchangeForSession(supabaseToken: '');
    await client.auth.signOut();
  }
}