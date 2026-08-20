import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/api_provider.dart';

class MenuProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<Map<String, dynamic>>> _itemsByCategory = {};
  List<Map<String, dynamic>> _dailyDeals = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategoryId;
  String _selectedMeatSubcategory = 'all';

  List<Map<String, dynamic>> get categories => _categories;
  Map<String, List<Map<String, dynamic>>> get itemsByCategory =>
      _itemsByCategory;
  List<Map<String, dynamic>> get dailyDeals => _dailyDeals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;
  String get selectedMeatSubcategory => _selectedMeatSubcategory;

  Future<void> fetchInitialData() async {
    if (_categories.isEmpty && _dailyDeals.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;

    // Tier 1: Try Go backend API
    try {
      final catalog = AniApi.instance.api.catalog;
      final cats = await catalog.menus();
      final items = await catalog.items();
      final deals = await catalog.deals();

      if (cats.isNotEmpty) {
        _categories = cats.map((m) => {
          'id': m.id,
          'menu_title': m.menuTitle,
          'image_url': m.imageUrl,
          'image': m.imageUrl,
        }).toList();
        _processItems(items.map(_itemToLegacyMap).toList());
        _dailyDeals = deals.map(_dealToLegacyMap).toList();
        _selectedCategoryId ??= 'meal';
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Go API catalog fetch error: $e, falling back to Supabase...');
    }

    // Tier 2: Try Supabase directly
    try {
      final supabase = Supabase.instance.client;
      final catsData = await supabase.from('menus').select().order('id');
      final itemsData = await supabase.from('items').select().eq('is_available', true);
      final dealsData = await supabase.from('daily_deals').select().eq('is_active', true);

      if (catsData.isNotEmpty) {
        _categories = List<Map<String, dynamic>>.from(catsData);
        _processItems(itemsData);
        _dailyDeals = List<Map<String, dynamic>>.from(dealsData);
        _selectedCategoryId ??= 'meal';
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Supabase direct catalog fetch error: $e, using default catalog...');
    }

    // Tier 3: Default Seed Catalog (Zero-Wait Guarantee)
    _categories = [
      {'id': 'meal', 'menu_title': 'Meal / Lunch', 'image': 'assets/images/hero.png'},
      {'id': 'chicken', 'menu_title': 'Chicken', 'image': 'assets/images/hero.png'},
      {'id': 'mutton', 'menu_title': 'Mutton', 'image': 'assets/images/hero.png'},
      {'id': 'fish', 'menu_title': 'Fish & Seafood', 'image': 'assets/images/hero.png'},
      {'id': 'eggs', 'menu_title': 'Eggs', 'image': 'assets/images/hero.png'},
      {'id': 'store', 'menu_title': 'Store', 'image': 'assets/images/hero.png'},
    ];

    _itemsByCategory = {
      'chicken': [
        {'id': 'ch_1', 'catId': 'chicken', 'name': 'Fresh Chicken Breast (500g)', 'description': 'Tender, skinless & boneless cut.', 'price': 240, 'image': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=600&q=80'},
        {'id': 'ch_2', 'catId': 'chicken', 'name': 'Chicken Curry Cut (1kg)', 'description': 'Bone-in, juicy prime pieces.', 'price': 310, 'image': 'https://images.unsplash.com/photo-1587593810167-a84920ea0781?w=600&q=80'},
      ],
      'mutton': [
        {'id': 'mu_1', 'catId': 'mutton', 'name': 'Rich Goat Curry Cut (500g)', 'description': 'Rich, tender cuts from fresh goat meat.', 'price': 480, 'image': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&q=80'},
      ],
      'fish': [
        {'id': 'fi_1', 'catId': 'fish', 'name': 'Fresh Salmon Fillet (300g)', 'description': 'Omega-3 rich, deboned salmon cut.', 'price': 520, 'image': 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&q=80'},
      ],
      'eggs': [
        {'id': 'eg_1', 'catId': 'eggs', 'name': 'Farm Fresh Brown Eggs (Pack of 12)', 'description': 'Organic, protein-packed brown eggs.', 'price': 120, 'image': 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=600&q=80'},
      ],
      'store': [
        {'id': 'st_1', 'catId': 'store', 'name': 'Special Meat Masala (100g)', 'description': 'Authentic home blended spice powder.', 'price': 90, 'image': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&q=80'},
      ],
    };

    _dailyDeals = [
      {
        'id': 'deal_1',
        'title': 'Weekend Lunch Feast',
        'subtitle': 'Flat 20% OFF on all signature meal bowls',
        'tag_text': 'SPECIAL OFFER',
        'color_hex': '#F15A24',
        'icon_name': 'local_offer',
        'discount_percent': 20,
        'is_active': true,
      }
    ];

    _selectedCategoryId ??= 'meal';
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Maps a core Item into the legacy map shape consumed by the UI.
  static Map<String, dynamic> _itemToLegacyMap(Item item) => {
    'id': item.id,
    'menu_id': item.category,
    'item_title': item.name,
    'item_info': item.description ?? '',
    'item_price': item.price.paise ~/ 100,
    'thumbnail_url': item.imageUrl ?? 'assets/images/hero.png',
    'is_available': item.isAvailable,
  };

  // Maps a core DailyDeal into the legacy daily_deals row shape.
  static Map<String, dynamic> _dealToLegacyMap(DailyDeal deal) => {
    'id': deal.id,
    'title': deal.title,
    'subtitle': deal.description ?? '',
    'tag_text': 'Today Only',
    'color_hex': '#F15A24',
    'icon_name': 'local_offer',
    'banner_image_url': deal.bannerImageUrl,
    'image_url': deal.bannerImageUrl,
    'discount_percent': deal.discountPercent,
    'is_active': deal.isActive,
  };

  void _processItems(List<dynamic> data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final rawItem in data) {
      final item = Map<String, dynamic>.from(rawItem);
      final menuId = item['menu_id']?.toString() ?? 'other';
      grouped.putIfAbsent(menuId, () => []).add({
        'id': item['id'].toString(),
        'catId': menuId,
        'name': item['item_title'] ?? 'Unnamed',
        'description': item['item_info'] ?? '',
        'price': (item['item_price'] ?? 0).toInt(),
        'image': item['thumbnail_url'] ?? 'assets/images/hero.png',
        'image_url_2': item['thumbnail_url_2'],
        'image_url_3': item['thumbnail_url_3'],
      });
    }
    _itemsByCategory = grouped;
  }

  void setSelectedCategory(String? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void setSelectedMeatSubcategory(String id) {
    _selectedMeatSubcategory = id;
    notifyListeners();
  }

  List<Map<String, dynamic>> getDisplayItems() {
    if (_selectedCategoryId == 'all') {
      if (_selectedMeatSubcategory == 'all') {
        return _itemsByCategory.values.expand((e) => e).toList();
      }
      return _itemsByCategory[_selectedMeatSubcategory] ?? [];
    }
    if (_selectedCategoryId == 'meal') {
      return [];
    }
    return _itemsByCategory[_selectedCategoryId] ?? [];
  }
}