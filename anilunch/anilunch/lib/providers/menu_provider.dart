import 'package:anilunch_core/anilunch_core.dart';
import 'package:flutter/material.dart';
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

    try {
      final catalog = AniApi.instance.api.catalog;
      final cats = await catalog.menus();
      final items = await catalog.items();
      final deals = await catalog.deals();

      _categories = cats.map((m) => {
        'id': m.id,
        'menu_title': m.menuTitle,
        'image_url': m.imageUrl,
        'image': m.imageUrl,
      }).toList();
      _processItems(items.map(_itemToLegacyMap).toList());
      _itemsByCategory['store'] = [
        {'id': 'st_1', 'catId': 'store', 'name': 'Berrylush', 'price': 120, 'image': 'https://images.unsplash.com/photo-1588117260148-b47818741c74?w=600&q=80'},
        {'id': 'st_2', 'catId': 'store', 'name': 'Twinkle', 'price': 150, 'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&q=80'},
        {'id': 'st_3', 'catId': 'store', 'name': 'Tees', 'price': 110, 'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&q=80'},
        {'id': 'st_4', 'catId': 'store', 'name': 'Blazers', 'price': 130, 'image': 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&q=80'},
      ];
      _dailyDeals = deals.map(_dealToLegacyMap).toList();

      if (_selectedCategoryId == null) {
        _selectedCategoryId = 'meal';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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