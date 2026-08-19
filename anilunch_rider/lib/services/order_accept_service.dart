import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

class OrderAcceptService {
  static final _supabase = Supabase.instance.client;

  static Future<bool> acceptOrder(String orderId) async {
    // 1. Try the Go backend (server-authoritative accept).
    if (await ApiClient.acceptOrder(orderId)) {
      return true;
    }

    // 2. Fallback: accept-order edge function (JWT-verified, rider derived
    //    from the token server-side). The raw accept_order RPC is revoked
    //    from clients for security.
    try {
      final res = await _supabase.functions.invoke('accept-order', body: {
        'orderId': orderId,
      });
      final data = res.data;
      return data is Map && data['success'] == true;
    } catch (e) {
      debugPrint('acceptOrder (edge) error: $e');
      return false;
    }
  }
}
