import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../models/order.dart';

class MapTrackingWidget extends StatefulWidget {
  final OrderModel order;
  final bool isDelivering; // true = to customer, false = to restaurant

  const MapTrackingWidget({
    super.key,
    required this.order,
    required this.isDelivering,
  });

  @override
  State<MapTrackingWidget> createState() => _MapTrackingWidgetState();
}

class _MapTrackingWidgetState extends State<MapTrackingWidget> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  // Destination coords
  LatLng? _destination;

  @override
  void initState() {
    super.initState();
    _determineDestination();
    _requestPermissionAndStartTracking();
  }

  void _determineDestination() {
    if (widget.isDelivering) {
      if (widget.order.customerLat != null && widget.order.customerLng != null) {
        _destination = LatLng(widget.order.customerLat!, widget.order.customerLng!);
      } else {
        // Fallback for demo
        _destination = const LatLng(25.5788, 91.8933);
      }
    } else {
      if (widget.order.restaurantLat != null && widget.order.restaurantLng != null) {
        _destination = LatLng(widget.order.restaurantLat!, widget.order.restaurantLng!);
      } else {
        // Fallback fake restaurant location for demo if missing
        _destination = const LatLng(25.5750, 91.8850); 
      }
    }
  }

  Future<void> _requestPermissionAndStartTracking() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _startTracking();
    }
  }

  void _startTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    Geolocator.getCurrentPosition().then((pos) {
      if (mounted) {
        setState(() => _currentPosition = pos);
        _updateMarkersAndRoute();
        if (_mapController != null && _destination != null) {
          _fitBounds();
        }
      }
    });

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null && mounted) {
          setState(() {
            _currentPosition = position;
            _updateMarkersAndRoute();
          });
        }
      }
    );
  }

  void _updateMarkersAndRoute() {
    if (_currentPosition == null) return;
    final riderPos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    _markers.clear();
    // Rider Marker
    _markers.add(
      Marker(
        markerId: const MarkerId('rider'),
        position: riderPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    );

    // Destination Marker
    if (_destination != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: widget.isDelivering ? 'Customer' : 'Restaurant'),
        ),
      );
      
      _fetchRoute(riderPos, _destination!);
    }
  }

  Future<void> _fetchRoute(LatLng start, LatLng end) async {
    // Note: To draw polyline, we need the API key
    const String apiKey = "YOUR_API_KEY_HERE"; 
    PolylinePoints polylinePoints = PolylinePoints(apiKey: apiKey);
    
    // This will fail until a valid API key is provided, but sets up the structure
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        // ignore: deprecated_member_use
        request: PolylineRequest(
          origin: PointLatLng(start.latitude, start.longitude),
          destination: PointLatLng(end.latitude, end.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        if (mounted) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: const Color(0xFFFF9100),
                width: 5,
                points: polylineCoordinates,
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  void _fitBounds() {
    if (_currentPosition == null || _destination == null || _mapController == null) return;

    LatLngBounds bounds;
    final riderLat = _currentPosition!.latitude;
    final riderLng = _currentPosition!.longitude;
    final destLat = _destination!.latitude;
    final destLng = _destination!.longitude;

    if (riderLat > destLat && riderLng > destLng) {
      bounds = LatLngBounds(southwest: LatLng(destLat, destLng), northeast: LatLng(riderLat, riderLng));
    } else if (riderLng > destLng) {
      bounds = LatLngBounds(southwest: LatLng(riderLat, destLng), northeast: LatLng(destLat, riderLng));
    } else if (riderLat > destLat) {
      bounds = LatLngBounds(southwest: LatLng(destLat, riderLng), northeast: LatLng(riderLat, destLng));
    } else {
      bounds = LatLngBounds(southwest: LatLng(riderLat, riderLng), northeast: LatLng(destLat, destLng));
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_destination == null) {
      return Container(
        color: const Color(0xFF161616),
        child: const Center(
          child: Text(
            'Location data unavailable',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _destination!,
        zoom: 14,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentPosition != null) {
          _fitBounds();
        }
      },
    );
  }
}
