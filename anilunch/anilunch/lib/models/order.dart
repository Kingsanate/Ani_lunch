import 'delivery_address.dart';

class Order {
  final String id;
  final List<Map<String, dynamic>> items;
  final int total;
  final DeliveryAddress address;
  final String paymentMethod;
  final DateTime date;
  final String status;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.date,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'subtotal': total - 50,
      'delivery_fee': 50,
      'total_amount': total,
      'payment_method': paymentMethod,
      'status': status.toLowerCase(),
      'address': address.houseNo,
      'created_at': date.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id']?.toString() ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      total: (map['total_amount'] ?? 0).toInt(),
      address: DeliveryAddress.fromMap({
        'house_no': map['address']?.toString() ?? '',
      }),
      paymentMethod: map['payment_method'] ?? 'Unknown',
      date: map['order_time'] != null
          ? DateTime.parse(map['order_time'] as String)
          : (map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now()),
      status: map['status'] ?? 'Pending',
    );
  }
}
