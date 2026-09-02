import '../money.dart';

class Vendor {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double? locationLat;
  final double? locationLng;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vendor({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.locationLat,
    this.locationLng,
    required this.isOpen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: str(json, 'id'),
        name: str(json, 'name'),
        address: str(json, 'address'),
        phone: str(json, 'phone'),
        locationLat: optDouble(json, 'location_lat'),
        locationLng: optDouble(json, 'location_lng'),
        isOpen: boolOf(json, 'is_open'),
        createdAt: dateTimeOf(json, 'created_at'),
        updatedAt: dateTimeOf(json, 'updated_at'),
      );
}

class VendorOrderItem {
  final String id;
  final String itemId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money subtotal;
  final String? image;
  final Map<String, String>? customizations;

  const VendorOrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.image,
    this.customizations,
  });

  factory VendorOrderItem.fromJson(Map<String, dynamic> json) {
    Map<String, String>? customizations;
    if (json['customizations'] is Map) {
      customizations = (json['customizations'] as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return VendorOrderItem(
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

class VendorOrder {
  final String id;
  final String userId;
  final String status;
  final List<VendorOrderItem> items;
  final Money subtotal;
  final Money deliveryFee;
  final Money discount;
  final Money totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String specialNotes;
  final String? riderId;
  final DateTime orderTime;
  final String customerName;
  final String address;

  const VendorOrder({
    required this.id,
    required this.userId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.specialNotes = '',
    this.riderId,
    required this.orderTime,
    this.customerName = '',
    this.address = '',
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) => VendorOrder(
        id: str(json, 'id'),
        userId: str(json, 'user_id'),
        status: str(json, 'status'),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => VendorOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: Money.fromJson(json['subtotal']),
        deliveryFee: Money.fromJson(json['delivery_fee']),
        discount: Money.fromJson(json['discount']),
        totalAmount: Money.fromJson(json['total_amount']),
        paymentMethod: str(json, 'payment_method'),
        paymentStatus: str(json, 'payment_status'),
        specialNotes: str(json, 'special_notes'),
        riderId: optStr(json, 'rider_id'),
        orderTime: dateTimeOf(json, 'order_time'),
        customerName: str(json, 'customer_name'),
        address: str(json, 'address'),
      );
}

class VendorStats {
  final int ordersToday;
  final Money revenueToday;
  final int pendingCount;
  final int preparingCount;
  final int readyCount;
  final int completedToday;

  const VendorStats({
    required this.ordersToday,
    required this.revenueToday,
    required this.pendingCount,
    required this.preparingCount,
    required this.readyCount,
    required this.completedToday,
  });

  factory VendorStats.fromJson(Map<String, dynamic> json) => VendorStats(
        ordersToday: intOf(json, 'orders_today'),
        revenueToday: Money.fromJson(json['revenue_today']),
        pendingCount: intOf(json, 'pending_count'),
        preparingCount: intOf(json, 'preparing_count'),
        readyCount: intOf(json, 'ready_count'),
        completedToday: intOf(json, 'completed_today'),
      );
}
