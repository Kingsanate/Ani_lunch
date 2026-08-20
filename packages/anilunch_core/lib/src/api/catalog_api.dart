import '../models/catalog.dart';
import 'api_client.dart';

/// Public, cached catalog reads.
class CatalogApi {
  final ApiClient _client;

  CatalogApi(this._client);

  Future<List<Item>> items({String? category}) async {
    final data = await _client.get<List<dynamic>>(
      '/api/v1/catalog/items',
      query: category == null ? null : {'category': category},
      authenticated: false,
    );
    return data
        .map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Menu>> menus() async {
    final data = await _client.get<List<dynamic>>(
      '/api/v1/catalog/menus',
      authenticated: false,
    );
    return data
        .map((e) => Menu.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DailyDeal>> deals() async {
    final data = await _client.get<List<dynamic>>(
      '/api/v1/catalog/deals',
      authenticated: false,
    );
    return data
        .map((e) => DailyDeal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
