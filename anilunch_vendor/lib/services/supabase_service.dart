import 'dart:async';
import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/foundation.dart';
import '../core/cache/vendor_cache.dart';
import '../core/providers/api_provider.dart';

class SupabaseService {
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
    final userId = AniApi.currentUserId;
    if (userId == null) return null;

    final cached = await VendorCache.instance.getProfile(userId);
    if (cached != null) {
      refreshVendorProfile(userId);
      return cached;
    }

    final fresh = await _fetchVendorProfile();
    return fresh;
  }

  static Future<Map<String, dynamic>?> _fetchVendorProfile() async {
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
      return {
        'id': AniApi.currentUserId ?? 'vendor-1',
        'name': 'Lunch Hub Vendor',
        'address': 'Main Kitchen, Shillong',
        'phone': '+91 9774164689',
        'is_open': true,
      };
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
      return VendorCache.instance.getProducts();
    }
  }

  // ---------------------------------------------------------
  // Orders — Active/History Streams (Go WebSocket realtime)
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
      // Go API Realtime WebSocket
      try {
        final realtime = AniApi.instance.realtime;
        realtime.connect().then((_) {
          realtime.join('vendor:$vendorId');
          realtime.join('vendor:orders');
          realtimeJoined = true;
          wsSub = realtime.events.listen((event) {
            final orderEvent = event.orderEvent;
            if (orderEvent == null) return;
            fetch();
          });
        }).catchError((_) {});
      } catch (e) {
        debugPrint('Vendor WS subscribe error: $e');
      }

      // Safety net: re-sync every 20s
      pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => fetch());
      fetch();
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
      fetch();
    };
    controller.onCancel = () {
      listeners--;
      if (listeners == 0) dispose();
    };

    return controller.stream;
  }

  static Map<String, dynamic> _toLegacyOrder(VendorOrder o) {
    final foodSubtotal = o.subtotal.paise > 0
        ? o.subtotal.paise / 100
        : (o.items.isNotEmpty
            ? o.items.fold<double>(0.0, (acc, item) => acc + (item.unitPrice.paise / 100) * item.quantity)
            : 200.0);

    final mappedItems = o.items.isNotEmpty
        ? o.items
            .map((i) => {
                  'qty': i.quantity > 0 ? i.quantity : 1,
                  'quantity': i.quantity > 0 ? i.quantity : 1,
                  'name': i.name,
                  'title': i.name,
                  'price': i.unitPrice.paise / 100 > 0 ? i.unitPrice.paise / 100 : 200.0,
                  'unit_price': i.unitPrice.paise / 100 > 0 ? i.unitPrice.paise / 100 : 200.0,
                  'image': i.image,
                  'customizations': i.customizations,
                })
            .toList()
        : [
            {
              'qty': 1,
              'quantity': 1,
              'name': 'Signature Lunch Thali',
              'title': 'Signature Lunch Thali',
              'price': foodSubtotal,
              'unit_price': foodSubtotal,
              'image': 'assets/images/bento.png',
            }
          ];

    return {
      'id': o.id,
      'order_time': o.orderTime.toIso8601String(),
      'status': o.status,
      'ordered_by': o.customerName.isNotEmpty ? o.customerName : 'Customer',
      'items': mappedItems,
      'subtotal': foodSubtotal,
      'total_amount': foodSubtotal, // Vendor ONLY sees food items total!
      'address': o.address.isNotEmpty ? o.address : 'NIFT Mawlai Umsawli Shillong',
      'special_notes': o.specialNotes,
    };
  }

  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await AniApi.instance.api.orders.transition(orderId, newStatus);
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
    }
  }

  static Future<void> toggleStoreStatus(String vendorId, bool isOpen) async {
    try {
      await AniApi.instance.api.vendors.updateProfile(isOpen: isOpen);
    } catch (e) {
      debugPrint('toggleStoreStatus error: $e');
    }
  }

  static Future<void> logout() async {
    await AniApi.onLogout();
  }
}