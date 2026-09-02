import '../core/providers/api_provider.dart';

class LunchService {
  Future<List<Map<String, dynamic>>> getLunchProducts() async {
    try {
      final res = await AniApi.instance.api.client.get<List<dynamic>>(
        '/api/v1/catalog/meal_products',
        authenticated: false,
      );
      final list = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (list.isNotEmpty) return list;
      return _defaultThalis();
    } catch (e) {
      return _defaultThalis();
    }
  }

  static List<Map<String, dynamic>> _defaultThalis() => [
    {
      'id': '50e91272-8541-4e4b-af57-5f2a51c2dd69',
      'name': 'Khasi Thali',
      'item_title': 'Khasi Thali',
      'description': 'Pure Local Traditional Platter',
      'price': 200,
      'discount_price': 200,
      'rating': 4.9,
      'image_url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80',
      'is_available': true,
      'rice_options': ['White Rice', 'Red Rice'],
      'meat_options': ['Chicken', 'Pork', 'Beef', 'Fish'],
      'category': 'meal',
    },
    {
      'id': 'mizo-thali-7788-9900',
      'name': 'Mizo Thali',
      'item_title': 'Mizo Thali',
      'description': 'Authentic Tribal Lunch & Bai',
      'price': 200,
      'discount_price': 200,
      'rating': 4.9,
      'image_url': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&q=80',
      'is_available': true,
      'rice_options': ['Steamed Local Rice'],
      'meat_options': ['Smoked Pork', 'Boiled Chicken', 'Local Fish'],
      'category': 'meal',
    },
    {
      'id': 'naga-thali-3344-5566',
      'name': 'Naga Thali',
      'item_title': 'Naga Thali',
      'description': 'Smoked Meat with Bamboo Shoot',
      'price': 200,
      'discount_price': 200,
      'rating': 4.9,
      'image_url': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600&q=80',
      'is_available': true,
      'rice_options': ['Naga Sticky Rice', 'White Rice'],
      'meat_options': ['Smoked Pork & Axone', 'Spicy Chicken Curry'],
      'category': 'meal',
    },
    {
      'id': '001e758c-d57b-4310-9131-e0947019c517',
      'name': 'Indian Thali',
      'item_title': 'Indian Thali',
      'description': 'Classic North Indian Meal',
      'price': 150,
      'discount_price': 150,
      'rating': 4.8,
      'image_url': 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&q=80',
      'is_available': true,
      'rice_options': ['Jeera Rice', 'Plain Rice'],
      'meat_options': ['Chicken Curry', 'Mutton Curry'],
      'category': 'meal',
    },
  ];

  Future<Map<String, dynamic>?> getLunchById(String id) async {
    final list = await getLunchProducts();
    try {
      return list.firstWhere((p) => p['id'].toString() == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addToCart(Map<String, dynamic> product) async {}
}
