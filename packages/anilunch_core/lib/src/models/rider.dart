import '../money.dart';

class Rider {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final bool isApproved;
  final String approvalStatus;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Rider({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isOnline,
    this.latitude,
    this.longitude,
    required this.isApproved,
    required this.approvalStatus,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rider.fromJson(Map<String, dynamic> json) => Rider(
        id: str(json, 'id'),
        name: str(json, 'name'),
        phone: str(json, 'phone'),
        email: str(json, 'email'),
        isOnline: boolOf(json, 'is_online'),
        latitude: optDouble(json, 'latitude'),
        longitude: optDouble(json, 'longitude'),
        isApproved: boolOf(json, 'is_approved'),
        approvalStatus: str(json, 'approval_status'),
        rejectionReason: optStr(json, 'rejection_reason'),
        createdAt: dateTimeOf(json, 'created_at'),
        updatedAt: dateTimeOf(json, 'updated_at'),
      );
}

class RiderOrderItem {
  final String id;
  final String itemId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money subtotal;
  final String? image;
  final Map<String, String>? customizations;

  const RiderOrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.image,
    this.customizations,
  });

  factory RiderOrderItem.fromJson(Map<String, dynamic> json) {
    Map<String, String>? customizations;
    if (json['customizations'] is Map) {
      customizations = (json['customizations'] as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return RiderOrderItem(
      id: str(json, 'id'),
      itemId: str(json, 'item_id'),
      name: str(json, 'name'),
      quantity: intOf(json, 'quantity'),
      unitPrice: Money.fromJson(json['unit_price']),
      subtotal: Money.fromJson(json['subtotal']),
      image: optStr(json, 'image'),
      customizations: customizations,
    );
  }
}

class RiderOrder {
  final String id;
  final String userId;
  final String? vendorId;
  final String status;
  final List<RiderOrderItem> items;
  final Money subtotal;
  final Money deliveryFee;
  final Money totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String address;
  final double? latitude;
  final double? longitude;
  final String specialNotes;
  final DateTime orderTime;
  final String customerName;
  final String customerPhone;

  const RiderOrder({
    required this.id,
    required this.userId,
    this.vendorId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.address = '',
    this.latitude,
    this.longitude,
    this.specialNotes = '',
    required this.orderTime,
    this.customerName = '',
    this.customerPhone = '',
  });

  factory RiderOrder.fromJson(Map<String, dynamic> json) => RiderOrder(
        id: str(json, 'id'),
        userId: str(json, 'user_id'),
        vendorId: optStr(json, 'vendor_id'),
        status: str(json, 'status'),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => RiderOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: Money.fromJson(json['subtotal']),
        deliveryFee: Money.fromJson(json['delivery_fee']),
        totalAmount: Money.fromJson(json['total_amount']),
        paymentMethod: str(json, 'payment_method'),
        paymentStatus: str(json, 'payment_status'),
        address: str(json, 'address'),
        latitude: optDouble(json, 'latitude'),
        longitude: optDouble(json, 'longitude'),
        specialNotes: str(json, 'special_notes'),
        orderTime: dateTimeOf(json, 'order_time'),
        customerName: str(json, 'customer_name'),
        customerPhone: str(json, 'customer_phone'),
      );
}
