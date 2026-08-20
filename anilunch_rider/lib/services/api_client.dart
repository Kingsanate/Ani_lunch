import 'package:flutter/foundation.dart';
import '../core/providers/api_provider.dart';

/// ApiClient talks to the Go backend with the Go-issued access token (minted
/// via /auth/exchange). Every method returns false when the backend is
/// unreachable so callers can fall back to the legacy Supabase path.
class ApiClient {
  /// Claims a ready_for_pickup order. Returns true when the backend accepted.
  static Future<bool> acceptOrder(String orderId) async {
    try {
      await AniApi.instance.api.riders.acceptOrder(orderId);
      return true;
    } catch (e) {
      debugPrint('ApiClient.acceptOrder error: $e');
      return false;
    }
  }

  /// Server-authoritative status transition (picked_up, delivered, ...).
  static Future<bool> transitionOrder(String orderId, String status) async {
    try {
      await AniApi.instance.api.orders.transition(orderId, status);
      return true;
    } catch (e) {
      debugPrint('ApiClient.transitionOrder error: $e');
      return false;
    }
  }

  /// Toggles the rider online/offline state on the backend.
  static Future<bool> setAvailability(bool isOnline) async {
    try {
      await AniApi.instance.api.riders.setAvailability(isOnline);
      return true;
    } catch (e) {
      debugPrint('ApiClient.setAvailability error: $e');
      return false;
    }
  }

  /// Persists the rider's current GPS coordinates on the backend.
  static Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      await AniApi.instance.api.riders.updateLocation(latitude, longitude);
      return true;
    } catch (e) {
      debugPrint('ApiClient.updateLocation error: $e');
      return false;
    }
  }
}