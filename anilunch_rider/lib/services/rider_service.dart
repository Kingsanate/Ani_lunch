import 'package:flutter/foundation.dart';
import '../core/providers/api_provider.dart';
import '../core/sync/rider_sync_engine.dart';

class RiderService {
  /// Toggle online / offline status
  static Future<void> setOnlineStatus(String riderId, bool isOnline) async {
    try {
      await AniApi.instance.api.riders.setAvailability(isOnline);
    } catch (e) {
      debugPrint('setOnlineStatus error: $e');
      await RiderSyncEngine.instance.enqueue(
        riderId: riderId,
        action: 'update_online',
        payload: {'is_online': isOnline},
      );
    }
  }

  /// Update rider location
  static Future<void> updateLocation(
    String riderId,
    double latitude,
    double longitude,
  ) async {
    try {
      await AniApi.instance.api.riders.updateLocation(latitude, longitude);
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
