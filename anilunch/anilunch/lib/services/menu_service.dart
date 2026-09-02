import 'dart:async';
import '../core/providers/api_provider.dart';

class MenuService {
  Future<List<Map<String, dynamic>>> fetchMenus() async {
    try {
      final menus = await AniApi.instance.api.catalog.menus();
      return menus
          .map((m) => {
                'id': m.id,
                'menu_title': m.menuTitle,
                'image_url': m.imageUrl,
                'created_at': m.createdAt.toIso8601String(),
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    try {
      final items = await AniApi.instance.api.catalog.items();
      return items
          .map((i) => {
                'id': i.id,
                'item_title': i.name,
                'name': i.name,
                'item_price': i.price.paise ~/ 100,
                'price': i.price.paise ~/ 100,
                'category': i.category,
                'thumbnail_url': i.imageUrl,
                'image_url': i.imageUrl,
                'is_available': i.isAvailable,
                'rating': i.rating,
                'reviews_count': i.reviewsCount,
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDailyDeals() async {
    try {
      final deals = await AniApi.instance.api.catalog.deals();
      return deals
          .map((d) => {
                'id': d.id,
                'deal_title': d.title,
                'title': d.title,
                'description': d.description,
                'discount_percentage': d.discountPercent,
                'banner_image_url': d.bannerImageUrl,
                'is_active': d.isActive,
              })
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchAppSettings() async {
    try {
      return await AniApi.instance.api.client.get<Map<String, dynamic>>(
        '/api/v1/catalog/app_settings',
        authenticated: false,
      );
    } catch (e) {
      return null;
    }
  }

  StreamSubscription? subscribeToMenuChanges(void Function() callback) {
    try {
      final realtime = AniApi.instance.realtime;
      return realtime.events.listen((_) => callback());
    } catch (_) {
      return null;
    }
  }
}
