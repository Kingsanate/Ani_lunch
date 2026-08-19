import '../money.dart';

class OrderItemSummary {
  final String id;
  final String itemId;
  final String name;
  final Money unitPrice;
  final int quantity;
  final Money subtotal;

  /// Legacy snapshot: unit price in integer RUPEES (not paise).
  /// Kept only for backward compatibility with legacy screens.
  final int price;
  final String? image;

  const OrderItemSummary({
    required this.id,
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.price,
    this.image,
  });

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) =>
      OrderItemSummary(
        id: str(json, 'id'),
        itemId: str(json, 'item_id'),
        name: str(json, 'name'),
        unitPrice: Money.fromJson(json['unit_price']),
        quantity: intOf(json, 'quantity'),
        subtotal: Money.fromJson(json['subtotal']),
        price: intOf(json, 'price'),
        image: optStr(json, 'image'),
      );
}

class Order {
  final String id;
  final String userId;
  final String? vendorId;
  final String? riderId;
  final String orderType;
  final String status;
  final Money subtotal;
  final Money deliveryFee;
  final Money discount;
  final Money totalAmount;
  final String? couponCode;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryStreet;
  final String deliveryCity;
  final String deliveryZip;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? specialNotes;
  final String? idempotencyKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemSummary> items;

  const Order({
    required this.id,
    required this.userId,
    this.vendorId,
    this.riderId,
    required this.orderType,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    this.couponCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryStreet,
    required this.deliveryCity,
    required this.deliveryZip,
    this.deliveryLat,
    this.deliveryLng,
    this.specialNotes,
    this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: str(json, 'id'),
        userId: str(json, 'user_id'),
        vendorId: optStr(json, 'vendor_id'),
        riderId: optStr(json, 'rider_id'),
        orderType: str(json, 'order_type'),
        status: str(json, 'status'),
        subtotal: Money.fromJson(json['subtotal']),
        deliveryFee: Money.fromJson(json['delivery_fee']),
        discount: Money.fromJson(json['discount']),
        totalAmount: Money.fromJson(json['total_amount']),
        couponCode: optStr(json, 'coupon_code'),
        paymentMethod: str(json, 'payment_method'),
        paymentStatus: str(json, 'payment_status'),
        deliveryStreet: str(json, 'delivery_street'),
        deliveryCity: str(json, 'delivery_city'),
        deliveryZip: str(json, 'delivery_zip'),
        deliveryLat: optDouble(json, 'delivery_lat'),
        deliveryLng: optDouble(json, 'delivery_lng'),
        specialNotes: optStr(json, 'special_notes'),
        idempotencyKey: optStr(json, 'idempotency_key'),
        createdAt: dateTimeOf(json, 'created_at'),
        updatedAt: dateTimeOf(json, 'updated_at'),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => OrderItemSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CreateOrderRequest {
  final String idempotencyKey;
  final String? vendorId;
  final String? orderType;
  final String paymentMethod;
  final String? couponCode;
  final String deliveryStreet;
  final String deliveryCity;
  final String deliveryZip;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? specialNotes;
  final List<OrderItemRequest> items;

  const CreateOrderRequest({
    required this.idempotencyKey,
    this.vendorId,
    this.orderType,
    required this.paymentMethod,
    this.couponCode,
    this.deliveryStreet = '',
    this.deliveryCity = '',
    this.deliveryZip = '',
    this.deliveryLat,
    this.deliveryLng,
    this.specialNotes,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'idempotency_key': idempotencyKey,
        'vendor_id': vendorId,
        'order_type': orderType,
        'payment_method': paymentMethod,
        'coupon_code': couponCode,
        'delivery_street': deliveryStreet,
        'delivery_city': deliveryCity,
        'delivery_zip': deliveryZip,
        'delivery_lat': deliveryLat,
        'delivery_lng': deliveryLng,
        'special_notes': specialNotes,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class OrderItemRequest {
  final String itemId;
  final int quantity;

  /// User's customization choices (e.g. {"Rice": "...", "Meat": "2x Chicken"})
  /// so extra-piece charges are priced server-side. Clients never set prices.
  final Map<String, String>? customizations;

  const OrderItemRequest({
    required this.itemId,
    required this.quantity,
    this.customizations,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
        if (customizations != null && customizations!.isNotEmpty)
          'customizations': customizations,
      };
}
