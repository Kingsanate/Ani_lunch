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
    this.totalAmount,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Backend uses 'ordered_by' for customer email and 'order_time' for timestamp
    final riderId = json['rider_id']?.toString() ?? '';

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
      totalAmount: (json['total_amount'] as num?)?.toDouble() ??
          (json['subtotal'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble(),
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
}
