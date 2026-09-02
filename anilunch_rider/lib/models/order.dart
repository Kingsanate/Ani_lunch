import 'dart:convert';

class OrderModel {
  final String id;
  final String status;
  final String? riderId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final double? customerLat;
  final double? customerLng;
  final double? restaurantLat;
  final double? restaurantLng;
  final List<dynamic> items;
  final double? subtotal;
  final double? deliveryFee;
  final double? totalAmount;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.status,
    this.riderId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerLat,
    this.customerLng,
    this.restaurantLat,
    this.restaurantLng,
    required this.items,
    this.subtotal,
    this.deliveryFee,
    this.totalAmount,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Backend uses 'ordered_by' for customer email and 'order_time' for timestamp
    final riderId = json['rider_id']?.toString() ?? '';

    final rawSubtotal = json['subtotal_paise'] != null
        ? (json['subtotal_paise'] is Map
            ? ((json['subtotal_paise']['paise'] as num?)?.toDouble() ?? 0.0) / 100
            : ((json['subtotal_paise'] as num?)?.toDouble() ?? 0.0) / 100)
        : (json['subtotal'] as num?)?.toDouble();

    final rawDeliveryFee = json['delivery_fee_paise'] != null
        ? (json['delivery_fee_paise'] is Map
            ? ((json['delivery_fee_paise']['paise'] as num?)?.toDouble() ?? 0.0) / 100
            : ((json['delivery_fee_paise'] as num?)?.toDouble() ?? 0.0) / 100)
        : (json['delivery_fee'] as num?)?.toDouble();

    final rawTotal = (json['total_amount_paise'] != null
            ? (json['total_amount_paise'] is Map
                ? ((json['total_amount_paise']['paise'] as num?)?.toDouble() ?? 0.0) / 100
                : ((json['total_amount_paise'] as num?)?.toDouble() ?? 0.0) / 100)
            : null) ??
        (json['total_amount'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ??
        (rawSubtotal != null && rawDeliveryFee != null ? rawSubtotal + rawDeliveryFee : null);

    return OrderModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      riderId: riderId.isEmpty ? null : riderId,
      customerName: json['customer_name']?.toString() ??
          json['ordered_by']?.toString() ??
          'Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerAddress: json['address']?.toString() ??
          json['delivery_address']?.toString() ??
          'Address not provided',
      customerLat: _parseDouble(json['customer_lat']),
      customerLng: _parseDouble(json['customer_lng']),
      restaurantLat: _parseDouble(json['restaurant_lat']),
      restaurantLng: _parseDouble(json['restaurant_lng']),
      items: _parseItems(json['items']),
      subtotal: rawSubtotal ?? ((rawTotal != null && rawTotal > 30) ? rawTotal - 30 : 200.0),
      deliveryFee: rawDeliveryFee ?? 30.0,
      totalAmount: rawTotal ?? ((rawSubtotal ?? 200.0) + (rawDeliveryFee ?? 30.0)),
      // Backend uses 'order_time' not 'created_at'
      createdAt: json['order_time'] != null
          ? DateTime.tryParse(json['order_time'].toString())
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
    );
  }

  static List<dynamic> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  String get shortId => id.length > 8 ? '#${id.substring(0, 8).toUpperCase()}' : '#$id';

  bool get hasRider => riderId != null && riderId!.isNotEmpty;

  OrderModel copyWith({
    String? id,
    String? status,
    String? riderId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? customerLat,
    double? customerLng,
    double? restaurantLat,
    double? restaurantLng,
    List<dynamic>? items,
    double? totalAmount,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      status: status ?? this.status,
      riderId: riderId ?? this.riderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
