import '../money.dart';

class User {
  final String id;
  final String? userId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? avatarUrl;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.avatarUrl,
    required this.isAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: str(json, 'id'),
        userId: optStr(json, 'user_id'),
        name: str(json, 'name'),
        email: str(json, 'email'),
        phone: str(json, 'phone'),
        address: str(json, 'address'),
        avatarUrl: optStr(json, 'avatar_url'),
        isAdmin: boolOf(json, 'is_admin'),
        createdAt: dateTimeOf(json, 'created_at'),
        updatedAt: dateTimeOf(json, 'updated_at'),
      );
}

class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? address;
  final String? avatarUrl;

  const UpdateProfileRequest({this.name, this.phone, this.address, this.avatarUrl});

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}

class Notification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String notificationType;
  final String? entityType;
  final String? entityId;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.notificationType,
    this.entityType,
    this.entityId,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: str(json, 'id'),
        userId: str(json, 'user_id'),
        title: str(json, 'title'),
        body: str(json, 'body'),
        notificationType: str(json, 'notification_type'),
        entityType: optStr(json, 'entity_type'),
        entityId: optStr(json, 'entity_id'),
        isRead: boolOf(json, 'is_read'),
        createdAt: dateTimeOf(json, 'created_at'),
      );
}

class PublicUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? avatarUrl;

  const PublicUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.avatarUrl,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) => PublicUser(
        id: str(json, 'id'),
        name: str(json, 'name'),
        email: str(json, 'email'),
        phone: str(json, 'phone'),
        address: str(json, 'address'),
        avatarUrl: optStr(json, 'avatar_url'),
      );
}

class PaymentIntent {
  final String orderId;
  final Money totalAmount;
  final double rupees;
  final String currency;
  final String paymentLink;
  final String upiIntent;
  final String keyId;

  const PaymentIntent({
    required this.orderId,
    required this.totalAmount,
    required this.rupees,
    required this.currency,
    required this.paymentLink,
    required this.upiIntent,
    required this.keyId,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent(
        orderId: str(json, 'order_id'),
        totalAmount: Money.fromJson(json['total_amount']),
        rupees: doubleOf(json, 'rupees'),
        currency: str(json, 'currency', 'INR'),
        paymentLink: str(json, 'payment_link'),
        upiIntent: str(json, 'upi_intent'),
        keyId: str(json, 'key_id'),
      );
}
