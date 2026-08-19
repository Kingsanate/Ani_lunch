// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:anilunch/providers/cart_provider.dart';

void main() {
  group('CartProvider', () {
    late CartProvider cartProvider;

    setUp(() {
      cartProvider = CartProvider();
    });

    group('toggleItem', () {
      test('adds item to cart when not present', () {
        cartProvider.toggleItem('item_1', 'cat_1');

        expect(cartProvider.hasItems, isTrue);
        expect(cartProvider.itemCount, 1);
        expect(cartProvider.meatCart['cat_1'], containsPair('item_1', 1));
      });

      test('removes item from cart when already present', () {
        cartProvider.toggleItem('item_1', 'cat_1');
        cartProvider.toggleItem('item_1', 'cat_1');

        expect(cartProvider.hasItems, isFalse);
        expect(cartProvider.itemCount, 0);
      });

      test('removes category when last item is removed', () {
        cartProvider.toggleItem('item_1', 'cat_1');
        cartProvider.toggleItem('item_2', 'cat_1');
        cartProvider.toggleItem('item_1', 'cat_1');
        cartProvider.toggleItem('item_2', 'cat_1');

        expect(cartProvider.meatCart.containsKey('cat_1'), isFalse);
      });

      test('tracks items across multiple categories', () {
        cartProvider.toggleItem('item_1', 'cat_1');
        cartProvider.toggleItem('item_a', 'cat_2');
        cartProvider.toggleItem('item_b', 'cat_2');

        expect(cartProvider.itemCount, 3);
        expect(cartProvider.meatCart['cat_1']!.length, 1);
        expect(cartProvider.meatCart['cat_2']!.length, 2);
      });
    });

    group('updateQuantity', () {
      test('sets quantity for an item', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 5);

        expect(cartProvider.meatCart['cat_1'], containsPair('item_1', 5));
        expect(cartProvider.itemCount, 5);
      });

      test('removes item when quantity is set to 0', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 3);
        cartProvider.updateQuantity('cat_1', 'item_1', 0);

        expect(cartProvider.meatCart.containsKey('cat_1'), isFalse);
        expect(cartProvider.itemCount, 0);
      });

      test('removes item when quantity is set to negative', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 2);
        cartProvider.updateQuantity('cat_1', 'item_1', -1);

        expect(cartProvider.meatCart.containsKey('cat_1'), isFalse);
      });

      test('updates existing quantity', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 2);
        cartProvider.updateQuantity('cat_1', 'item_1', 10);

        expect(cartProvider.meatCart['cat_1'], containsPair('item_1', 10));
        expect(cartProvider.itemCount, 10);
      });
    });

    group('incrementItem', () {
      test('increments item quantity by 1', () {
        cartProvider.toggleItem('item_1', 'cat_1');
        cartProvider.incrementItem('cat_1', 'item_1');

        expect(cartProvider.meatCart['cat_1'], containsPair('item_1', 2));
        expect(cartProvider.itemCount, 2);
      });

      test('adds item with quantity 1 if not present', () {
        cartProvider.incrementItem('cat_1', 'item_1');

        expect(cartProvider.meatCart['cat_1'], containsPair('item_1', 1));
      });

      test('increments from zero when not in cart', () {
        cartProvider.incrementItem('cat_1', 'item_1');
        cartProvider.incrementItem('cat_1', 'item_1');

        expect(cartProvider.meatCart['cat_1'], containsPair('item_1', 2));
      });
    });

    group('decrementItem', () {
      test('decrements item quantity by 1', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 3);
        cartProvider.decrementItem('cat_1', 'item_1');

        expect(cartProvider.meatCart['cat_1'], containsPair('item_1', 2));
        expect(cartProvider.itemCount, 2);
      });

      test('removes item when quantity reaches 1', () {
        cartProvider.toggleItem('item_1', 'cat_1');
        cartProvider.decrementItem('cat_1', 'item_1');

        expect(cartProvider.meatCart.containsKey('cat_1'), isFalse);
        expect(cartProvider.itemCount, 0);
      });

      test('does nothing when category does not exist', () {
        cartProvider.decrementItem('nonexistent', 'item_1');

        expect(cartProvider.hasItems, isFalse);
      });
    });

    group('clearCart', () {
      test('removes all items from cart', () {
        cartProvider.toggleItem('item_1', 'cat_1');
        cartProvider.toggleItem('item_2', 'cat_1');
        cartProvider.toggleItem('item_a', 'cat_2');

        cartProvider.clearCart();

        expect(cartProvider.hasItems, isFalse);
        expect(cartProvider.itemCount, 0);
        expect(cartProvider.meatCart, isEmpty);
      });
    });

    group('calculateTotal', () {
      test('returns 0 for empty cart', () {
        final total = cartProvider.calculateTotal({});

        expect(total, 0);
      });

      test('calculates total correctly with single item', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 3);

        final categoryData = {
          'cat_1': [
            {'id': 'item_1', 'name': 'Chicken', 'price': 100},
          ],
        };

        final total = cartProvider.calculateTotal(categoryData);

        expect(total, 300);
      });

      test('calculates total correctly with multiple items and categories', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 2);
        cartProvider.updateQuantity('cat_1', 'item_2', 1);
        cartProvider.updateQuantity('cat_2', 'item_a', 3);

        final categoryData = {
          'cat_1': [
            {'id': 'item_1', 'name': 'Chicken', 'price': 100},
            {'id': 'item_2', 'name': 'Fish', 'price': 150},
          ],
          'cat_2': [
            {'id': 'item_a', 'name': 'Mutton', 'price': 200},
          ],
        };

        final total = cartProvider.calculateTotal(categoryData);

        expect(total, 950); // (2 * 100) + (1 * 150) + (3 * 200)
      });

      test('ignores items not found in category data', () {
        cartProvider.updateQuantity('cat_1', 'missing_item', 5);

        final categoryData = {
          'cat_1': [
            {'id': 'item_1', 'name': 'Chicken', 'price': 100},
          ],
        };

        final total = cartProvider.calculateTotal(categoryData);

        expect(total, 0);
      });
    });

    group('getCartItems', () {
      test('returns empty list for empty cart', () {
        final items = cartProvider.getCartItems({});

        expect(items, isEmpty);
      });

      test('returns cart items with qty and catId', () {
        cartProvider.updateQuantity('cat_1', 'item_1', 2);

        final categoryData = {
          'cat_1': [
            {'id': 'item_1', 'name': 'Chicken', 'price': 100},
          ],
        };

        final items = cartProvider.getCartItems(categoryData);

        expect(items.length, 1);
        expect(items[0]['id'], 'item_1');
        expect(items[0]['name'], 'Chicken');
        expect(items[0]['price'], 100);
        expect(items[0]['qty'], 2);
        expect(items[0]['catId'], 'cat_1');
      });
    });
  });
}
