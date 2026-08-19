import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  Map<String, Map<String, int>> _meatCart = {};

  Map<String, Map<String, int>> get meatCart => _meatCart;

  int get itemCount {
    int count = 0;
    for (final cart in _meatCart.values) {
      for (final qty in cart.values) {
        count += qty;
      }
    }
    return count;
  }

  bool get hasItems => _meatCart.isNotEmpty;

  void toggleItem(String itemId, String catId) {
    final bucket = _meatCart.putIfAbsent(catId, () => {});
    if (bucket.containsKey(itemId)) {
      bucket.remove(itemId);
      if (bucket.isEmpty) _meatCart.remove(catId);
    } else {
      bucket[itemId] = 1;
    }
    notifyListeners();
  }

  void updateQuantity(String catId, String itemId, int quantity) {
    if (quantity <= 0) {
      final bucket = _meatCart[catId];
      if (bucket != null) {
        bucket.remove(itemId);
        if (bucket.isEmpty) _meatCart.remove(catId);
      }
    } else {
      _meatCart.putIfAbsent(catId, () => {})[itemId] = quantity;
    }
    notifyListeners();
  }

  void incrementItem(String catId, String itemId) {
    final bucket = _meatCart.putIfAbsent(catId, () => {});
    bucket[itemId] = (bucket[itemId] ?? 0) + 1;
    notifyListeners();
  }

  void decrementItem(String catId, String itemId) {
    final bucket = _meatCart[catId];
    if (bucket == null) return;
    final current = bucket[itemId] ?? 1;
    if (current <= 1) {
      bucket.remove(itemId);
      if (bucket.isEmpty) _meatCart.remove(catId);
    } else {
      bucket[itemId] = current - 1;
    }
    notifyListeners();
  }

  void clearCart() {
    _meatCart.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getCartItems(
      Map<String, List<Map<String, dynamic>>> allCategoryData) {
    final List<Map<String, dynamic>> result = [];
    _meatCart.forEach((catId, cart) {
      final items = allCategoryData[catId] ?? [];
      cart.forEach((itemId, qty) {
        final idx = items.indexWhere((i) => i['id'] == itemId);
        if (idx != -1) {
          result.add({
            ...items[idx],
            'qty': qty,
            'catId': catId,
          });
        }
      });
    });
    return result;
  }

  int calculateTotal(
      Map<String, List<Map<String, dynamic>>> allCategoryData) {
    int total = 0;
    _meatCart.forEach((catId, cart) {
      final items = allCategoryData[catId] ?? [];
      cart.forEach((itemId, qty) {
        final idx = items.indexWhere((i) => i['id'] == itemId);
        if (idx != -1) {
          total += (items[idx]['price'] as int) * qty;
        }
      });
    });
    return total;
  }
}
