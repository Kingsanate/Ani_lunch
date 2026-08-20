import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/lunch_service.dart';

class LunchProvider extends ChangeNotifier {
  final LunchService _lunchService = LunchService();

  static final List<Map<String, dynamic>> defaultMeals = [
    {
      'id': 'meal-1',
      'name': 'Indian Thali',
      'item_title': 'Indian Thali',
      'description': 'Pure Indian lunch combo with rice, dal, subji & roti',
      'price': 150,
      'discount_price': 150,
      'image_url': 'assets/images/bento.png',
      'thumbnail_url': 'assets/images/bento.png',
      'is_available': true,
      'category': 'meal',
    },
    {
      'id': 'meal-2',
      'name': 'Mizo Thali',
      'item_title': 'Mizo Thali',
      'description': 'Pure local tribal meal combo with organic vegetables',
      'price': 200,
      'discount_price': 200,
      'image_url': 'assets/images/pork.png',
      'thumbnail_url': 'assets/images/pork.png',
      'is_available': true,
      'category': 'meal',
    },
    {
      'id': 'meal-3',
      'name': 'Naga Thali',
      'item_title': 'Naga Thali',
      'description': 'Pure Naga authentic specialty platter with bamboo shoot',
      'price': 200,
      'discount_price': 200,
      'image_url': 'assets/images/chicken.png',
      'thumbnail_url': 'assets/images/chicken.png',
      'is_available': true,
      'category': 'meal',
    },
    {
      'id': 'meal-4',
      'name': 'Khasi Thali',
      'item_title': 'Khasi Thali',
      'description': 'Traditional Khasi lunch platter with local herbs',
      'price': 200,
      'discount_price': 200,
      'image_url': 'assets/images/beef.png',
      'thumbnail_url': 'assets/images/beef.png',
      'is_available': true,
      'category': 'meal',
    },
  ];

  List<Map<String, dynamic>> _products = List.from(defaultMeals);
  bool _isLoading = false;
  String? _error;
  final List<Map<String, dynamic>> _cart = [];
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> get products => _products.isNotEmpty ? _products : defaultMeals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get cart => _cart;

  int get cartTotal {
    int total = 0;
    for (final item in _cart) {
      final price = item['custom_price'] ??
          item['product']['discount_price'] ??
          item['product']['item_price'] ??
          item['product']['price'] ??
          0;
      final quantity = item['quantity'] ?? 1;
      total += (price as int) * (quantity as int);
    }
    return total;
  }

  int get cartItemCount {
    int count = 0;
    for (final item in _cart) {
      count += (item['quantity'] as int?) ?? 1;
    }
    return count;
  }

  Future<void> fetchProducts() async {
    _error = null;

    try {
      final fresh = await _lunchService.getLunchProducts();
      if (fresh.isNotEmpty) {
        _products = fresh;
        notifyListeners();
      }
    } catch (e) {
      // Retain existing products silently
    }
  }

  void addToCart(Map<String, dynamic> product, {Map<String, String>? customizations, int? customPrice}) {
    final existingIndex = _cart.indexWhere((item) {
      if (item['product']['id'] != product['id']) return false;
      
      final itemCustomizations = item['customizations'] as Map<String, String>?;
      if (customizations == null && itemCustomizations == null) return true;
      if (customizations == null || itemCustomizations == null) return false;
      
      if (customizations.length != itemCustomizations.length) return false;
      for (final key in customizations.keys) {
        if (customizations[key] != itemCustomizations[key]) return false;
      }
      return true;
    });

    if (existingIndex >= 0) {
      _cart[existingIndex]['quantity'] += 1;
    } else {
      final cartItemId = DateTime.now().millisecondsSinceEpoch.toString();
      _cart.add({
        'cartItemId': cartItemId,
        'product': product,
        'quantity': 1,
        if (customizations != null) 'customizations': customizations,
        if (customPrice != null) 'custom_price': customPrice,
      });
    }
    notifyListeners();
  }

  void removeFromCart(String id, {bool isCartItemId = false}) {
    if (isCartItemId) {
      _cart.removeWhere((item) => item['cartItemId'] == id);
    } else {
      _cart.removeWhere((item) => item['product']['id'] == id);
    }
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity, {bool isCartItemId = false}) {
    if (newQuantity <= 0) {
      removeFromCart(id, isCartItemId: isCartItemId);
      return;
    }
    final index = isCartItemId
        ? _cart.indexWhere((item) => item['cartItemId'] == id)
        : _cart.indexWhere((item) => item['product']['id'] == id);
        
    if (index >= 0) {
      _cart[index]['quantity'] = newQuantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  void subscribeToChanges() {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('public:lunch_provider')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meal_products',
          callback: (payload) => fetchProducts(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
