import 'package:anilunch_core/anilunch_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('formats rupees from paise', () {
      expect(const Money(10050).format(), '₹100.50');
      expect(const Money(0).format(), '₹0.00');
      expect(const Money(500).toRupees(), 5.0);
    });

    test('arithmetic stays in paise', () {
      final subtotal = const Money(25000) + const Money(3000);
      expect(subtotal.paise, 28000);
      expect(subtotal - const Money(2000), const Money(26000));
    });

    test('comparison', () {
      expect(const Money(50000) >= const Money(50000), isTrue);
      expect(const Money(100) < const Money(200), isTrue);
    });
  });

  group('Order model', () {
    test('parses paise money and the legacy rupees price field', () {
      final order = Order.fromJson({
        'id': 'ORD-1',
        'user_id': 'u1',
        'order_type': 'meat',
        'status': 'pending_payment',
        'subtotal': 10050,
        'delivery_fee': 3000,
        'discount': 0,
        'total_amount': 13050,
        'payment_method': 'cod',
        'payment_status': 'pending',
        'delivery_street': 'Street',
        'delivery_city': 'City',
        'delivery_zip': '560001',
        'created_at': '2026-08-19T10:00:00Z',
        'updated_at': '2026-08-19T10:00:00Z',
        'items': [
          {
            'id': 'i1',
            'item_id': 'it1',
            'name': 'Chicken',
            'unit_price': 10050,
            'quantity': 2,
            'subtotal': 20100,
            'price': 100,
          }
        ],
      });

      expect(order.subtotal, const Money(10050));
      expect(order.items.single.unitPrice, const Money(10050));
      expect(order.items.single.price, 100);
      expect(order.totalAmount.format(), '₹130.50');
    });
  });

  group('Catalog models', () {
    test('Item parses optional fields', () {
      final item = Item.fromJson({
        'id': 'it1',
        'name': 'Paneer',
        'price': 12000,
        'category': 'Veg',
        'is_available': true,
        'preparation_min': 20,
        'rating': 4.5,
        'reviews_count': 12,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      expect(item.price, const Money(12000));
      expect(item.vendorId, isNull);
      expect(item.rating, 4.5);
    });
  });

  group('WS event parsing', () {
    test('distinguishes control vs event frames', () {
      final orderEvt = WsEvent({
        'event_id': 'evt-1',
        'event_type': 'orders.created',
        'order_id': 'ORD-1',
        'status': 'pending',
        'total_amount': 13050,
        'timestamp': '2026-08-19T10:00:00Z',
      });
      expect(orderEvt.isOrderEvent, isTrue);
      expect(orderEvt.orderEvent?.orderId, 'ORD-1');
      expect(orderEvt.orderEvent?.totalAmount, const Money(13050));

      final gps = WsEvent({
        'rider_id': 'r1',
        'latitude': 12.97,
        'longitude': 77.59,
        'timestamp': '2026-08-19T10:00:00Z',
      });
      expect(gps.isRiderLocation, isTrue);
      expect(gps.riderLocation?.latitude, 12.97);
    });
  });
}