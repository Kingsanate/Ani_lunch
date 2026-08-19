import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'rider_service.dart';

/// LocationTracker uploads the rider's live GPS at an adaptive cadence:
/// - active (carrying an order): every 10s
/// - idle: every 30s
///
/// Location is uploaded separately from order writes (PUT /riders/me/location)
/// so tracking traffic never contends with the order hot path.
class LocationTracker {
  static LocationTracker? _instance;

  static LocationTracker get instance =>
      _instance ??= LocationTracker._();

  static const Duration activeInterval = Duration(seconds: 10);
  static const Duration idleInterval = Duration(seconds: 30);

  Timer? _timer;
  bool _active = false;
  bool _permissionGranted = false;
  String? _riderId;

  LocationTracker._();

  /// Starts periodic location uploads (idle cadence until an order arrives).
  Future<void> start(String riderId) async {
    _riderId = riderId;
    _permissionGranted = await _ensurePermission();
    if (!_permissionGranted) {
      debugPrint('LocationTracker: location permission denied, tracking disabled');
      return;
    }
    _restartTimer();
    debugPrint('LocationTracker: started (idle every 30s, active every 10s)');
  }

  /// Switches cadence when the rider picks up / drops an active order.
  void setActive(bool active) {
    if (_active == active) return;
    _active = active;
    if (_timer != null) {
      _restartTimer();
    }
    debugPrint('LocationTracker: cadence ${active ? "active (10s)" : "idle (30s)"}');
  }

  /// Stops all uploads (logout).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> _ensurePermission() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_active ? activeInterval : idleInterval, (_) {
      _report();
    });
  }

  Future<void> _report() async {
    try {
      final riderId = _riderId;
      if (riderId == null) return;

      final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          )
          .timeout(const Duration(seconds: 7));

      await RiderService.updateLocation(
        riderId,
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint('LocationTracker: report failed: $e');
    }
  }
}