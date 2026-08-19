import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../money.dart';

/// Control frames from the gateway: {"type":"joined"|"error"|"pong"}.
class WsControlMessage {
  final String type;
  final String? channel;
  final String? message;

  const WsControlMessage({required this.type, this.channel, this.message});
}

/// A raw event frame delivered on a joined channel. Event frames are pushed
/// as-is (no envelope): order events carry `event_type`/`order_id`, rider
/// GPS frames carry `rider_id`/`latitude`.
class WsEvent {
  final Map<String, dynamic> data;

  const WsEvent(this.data);

  bool get isOrderEvent => data['event_type'] is String;

  bool get isRiderLocation => data['rider_id'] is String && data['latitude'] is num;

  /// order:... / rider:... / vendor:... channel this event was received on.
  String? get channel => data['channel'] as String?;

  OrderWsEvent? get orderEvent => isOrderEvent ? OrderWsEvent.from(data) : null;

  RiderLocationWsEvent? get riderLocation =>
      isRiderLocation ? RiderLocationWsEvent.from(data) : null;
}

class OrderWsEvent {
  final String eventId;
  final String eventType;
  final String orderId;
  final String? userId;
  final String? vendorId;
  final String? riderId;
  final String status;
  final Money? totalAmount;
  final String? idempotencyKey;
  final DateTime? timestamp;

  const OrderWsEvent({
    required this.eventId,
    required this.eventType,
    required this.orderId,
    this.userId,
    this.vendorId,
    this.riderId,
    required this.status,
    this.totalAmount,
    this.idempotencyKey,
    this.timestamp,
  });

  factory OrderWsEvent.from(Map<String, dynamic> json) => OrderWsEvent(
        eventId: (json['event_id'] as String?) ?? '',
        eventType: (json['event_type'] as String?) ?? '',
        orderId: (json['order_id'] as String?) ?? '',
        userId: json['user_id'] as String?,
        vendorId: json['vendor_id'] as String?,
        riderId: json['rider_id'] as String?,
        status: (json['status'] as String?) ?? '',
        totalAmount:
            json['total_amount'] is num ? Money.fromJson(json['total_amount']) : null,
        idempotencyKey: json['idempotency_key'] as String?,
        timestamp: json['timestamp'] is String
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
      );
}

class RiderLocationWsEvent {
  final String riderId;
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  const RiderLocationWsEvent({
    required this.riderId,
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  factory RiderLocationWsEvent.from(Map<String, dynamic> json) =>
      RiderLocationWsEvent(
        riderId: (json['rider_id'] as String?) ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        timestamp: json['timestamp'] is String
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
      );
}

/// Scoped WebSocket client for the AniLunch realtime gateway.
///
/// Auth uses the Go-issued access token passed as `?token=`. The client
/// emits raw event frames (order lifecycle + rider GPS) and gateway control
/// frames (joined/error/pong). Call [connect] once, then [join]/[leave].
class RealtimeClient {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final Duration pingInterval;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final _controls = StreamController<WsControlMessage>.broadcast();
  final _events = StreamController<WsEvent>.broadcast();
  Timer? _pingTimer;
  bool _disposed = false;

  /// Emits gateway control frames (joined / error / pong).
  Stream<WsControlMessage> get controls => _controls.stream;

  /// Emits raw event frames from joined channels.
  Stream<WsEvent> get events => _events.stream;

  bool get isConnected => _channel != null;

  RealtimeClient({
    required this.baseUrl,
    required this.tokenProvider,
    this.pingInterval = const Duration(seconds: 30),
  });

  /// Opens the WebSocket and starts the ping timer. Throws on failure.
  Future<void> connect() async {
    if (_disposed) {
      throw StateError('realtime: client is closed');
    }
    if (_channel != null) return;
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw StateError('realtime: no access token available');
    }
    final wsBase = baseUrl.replaceFirst('http://', 'ws://').replaceFirst(
        'https://', 'wss://');
    final uri = Uri.parse('$wsBase/api/v1/ws?token=$token');
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _sub = channel.stream.listen(
      (data) => _handleFrame(data),
      onError: (Object e) {
        _teardown();
      },
      onDone: () => _teardown(),
      cancelOnError: true,
    );
    _pingTimer = Timer.periodic(pingInterval, (_) => ping());
  }

  void join(String channel) => _send({'type': 'join', 'channel': channel});

  void leave(String channel) => _send({'type': 'leave', 'channel': channel});

  void ping() => _send({'type': 'ping'});

  void _send(Map<String, dynamic> frame) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(frame));
    } catch (_) {
      // channel closed
    }
  }

  void _handleFrame(dynamic data) {
    if (data is! String) return;
    Map<String, dynamic> json;
    try {
      json = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (json['type'] is String) {
      _controls.add(WsControlMessage(
        type: json['type'] as String,
        channel: json['channel'] as String?,
        message: json['message'] as String?,
      ));
      return;
    }
    _events.add(WsEvent(json));
  }

  void _teardown() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel = null;
  }

  Future<void> close() async {
    _disposed = true;
    _teardown();
    await _channel?.sink.close();
    await _controls.close();
    await _events.close();
  }
}