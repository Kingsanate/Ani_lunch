// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:anilunch/models/order.dart';
import 'package:anilunch/models/delivery_address.dart';

void main() {
  group('Order', () {
    final address = DeliveryAddress(
      id: 'addr_1',
      fullName: 'John Doe',
      phoneNumber: '9876543210',
      houseNo: '123',
      area: 'MG Road',
      city: 'Mumbai',
      state: 'Maharashtra',
      pincode: '400001',
    );

    final now = DateTime(2026, 6, 7, 14, 30, 0);

    test('fromMap parses all fields correctly', () {
      final map = {
        'id': 'order_001',
        'items': [
          {'id': 'item_1', 'name': 'Chicken Curry', 'price': 150, 'qty': 2},
        ],
        'total_amount': 350,
        'payment_method': 'COD',
        'status': 'Pending',
        'address': '123',
        'order_time': '2026-06-07T14:30:00.000',
      };

      final order = Order.fromMap(map);

      expect(order.id, 'order_001');
      expect(order.items.length, 1);
      expect(order.items[0]['name'], 'Chicken Curry');
      expect(order.total, 350);
      expect(order.paymentMethod, 'COD');
      expect(order.status, 'Pending');
      expect(order.address.houseNo, '123');
      expect(order.date, now);
    });

    test('fromMap uses created_at fallback when order_time is missing', () {
      final map = {
        'id': 'order_002',
        'items': [],
        'total_amount': 250,
        'payment_method': 'Card',
        'address': '456',
        'created_at': '2026-06-07T10:00:00.000',
      };

      final order = Order.fromMap(map);

      expect(order.date, DateTime(2026, 6, 7, 10, 0, 0));
    });

    test('fromMap defaults status to Pending', () {
      final map = {
        'id': 'order_003',
        'items': [],
        'total_amount': 100,
        'payment_method': 'COD',
        'address': '789',
      };

      final order = Order.fromMap(map);

      expect(order.status, 'Pending');
    });

    test('fromMap defaults paymentMethod to Unknown', () {
      final map = {
        'id': 'order_004',
        'items': [],
        'total_amount': 100,
        'address': '789',
      };

      final order = Order.fromMap(map);

      expect(order.paymentMethod, 'Unknown');
    });

    test('fromMap defaults total to 0', () {
      final map = {
        'id': 'order_005',
        'items': [],
        'payment_method': 'COD',
        'address': '789',
      };

      final order = Order.fromMap(map);

      expect(order.total, 0);
    });

    test('fromMap defaults id to empty string', () {
      final map = {
        'items': [],
        'total_amount': 100,
        'payment_method': 'COD',
        'address': '789',
      };

      final order = Order.fromMap(map);

      expect(order.id, '');
    });

    test('status defaults to Pending in constructor', () {
      final order = Order(
        id: 'order_006',
        items: [],
        total: 200,
        address: address,
        paymentMethod: 'COD',
        date: now,
      );

      expect(order.status, 'Pending');
    });

    test('custom status is used when provided', () {
      final order = Order(
        id: 'order_007',
        items: [],
        total: 200,
        address: address,
        paymentMethod: 'COD',
        date: now,
        status: 'Delivered',
      );

      expect(order.status, 'Delivered');
    });

    test('toMap produces correct map', () {
      final order = Order(
        id: 'order_008',
        items: [
          {'id': 'item_1', 'name': 'Biryani', 'price': 200, 'qty': 1},
        ],
        total: 250,
        address: address,
        paymentMethod: 'COD',
        date: now,
        status: 'Pending',
      );

      final map = order.toMap();

      expect(map['items'], order.items);
      expect(map['subtotal'], 200);
      expect(map['delivery_fee'], 50);
      expect(map['total_amount'], 250);
      expect(map['payment_method'], 'COD');
      expect(map['status'], 'pending');
      expect(map['address'], '123');
      expect(map['created_at'], '2026-06-07T14:30:00.000');
    });
  });
}
