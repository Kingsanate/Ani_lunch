import 'package:flutter/foundation.dart';
import '../core/providers/api_provider.dart';

/// ApiClient talks to the Go backend with the Go-issued access token (minted
/// via /auth/exchange). Every method returns false when the backend is
/// unreachable so callers can fall back to the legacy Supabase path.
class ApiClient {
  /// Server-authoritative status transition (preparing, ready_for_pickup, ...).
  static Future<bool> transitionOrder(String orderId, String status) async {
    try {
      await AniApi.instance.api.orders.transition(orderId, status);
      return true;
    } catch (e) {
      debugPrint('ApiClient.transitionOrder error: $e');
      return false;
    }
  }
}