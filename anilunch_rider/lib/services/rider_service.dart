import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/sync/rider_sync_engine.dart';
import 'api_client.dart';

class RiderService {
  static final _supabase = Supabase.instance.client;

  /// Toggle online / offline. Tries the Go backend first, falls back to
  /// Supabase, and on network failure the mutation is queued and retried by
  /// RiderSyncEngine (at-least-once, LWW).
  static Future<void> setOnlineStatus(String riderId, bool isOnline) async {
    if (await ApiClient.setAvailability(isOnline)) {
      return;
    }

    try {
      await _supabase
          .from('riders')
          .update({'is_online': isOnline})
          .eq('id', riderId);
    } catch (e) {
      debugPrint('setOnlineStatus error: $e');
      await RiderSyncEngine.instance.enqueue(
        riderId: riderId,
        action: 'update_online',
        payload: {'is_online': isOnline},
      );
    }
  }

  /// Update rider location via the Go backend, falling back to Supabase.
  /// Queued for retry when offline.
  static Future<void> updateLocation(
    String riderId,
    double latitude,
    double longitude,
  ) async {
    if (await ApiClient.updateLocation(latitude, longitude)) {
      return;
    }

    try {
      await _supabase.from('riders').update({
        'latitude': latitude,
        'longitude': longitude,
      }).eq('id', riderId);
    } catch (e) {
      debugPrint('updateLocation error: $e');
      await RiderSyncEngine.instance.enqueue(
        riderId: riderId,
        action: 'update_location',
        payload: {'latitude': latitude, 'longitude': longitude},
      );
    }
  }
}
