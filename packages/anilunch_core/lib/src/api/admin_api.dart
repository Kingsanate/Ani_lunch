import '../models/admin.dart';
import 'api_client.dart';

class AdminApi {
  final ApiClient _client;

  AdminApi(this._client);

  Future<DashboardStats> dashboard() async {
    final data = await _client
        .get<Map<String, dynamic>>('/api/v1/admin/dashboard');
    return DashboardStats.fromJson(data);
  }

  Future<List<AdminOrder>> orders({String? status}) async {
    final data = await _client.get<List<dynamic>>(
      '/api/v1/admin/orders',
      query: status == null ? null : {'status': status},
    );
    return data
        .map((e) => AdminOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminUser>> users() async {
    final data =
        await _client.get<List<dynamic>>('/api/v1/admin/users');
    return data
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminRider>> riders({String? status}) async {
    final data = await _client.get<List<dynamic>>(
      '/api/v1/admin/riders',
      query: status == null ? null : {'status': status},
    );
    return data
        .map((e) => AdminRider.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminRider> setRiderApproval(
    String riderId, {
    required String approvalStatus,
    String? rejectionReason,
  }) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/admin/riders/$riderId/approval',
      body: {
        'approval_status': approvalStatus,
        'rejection_reason': rejectionReason,
      },
    );
    return AdminRider.fromJson(data);
  }

  Future<AppSettings> getSettings() async {
    final data = await _client
        .get<Map<String, dynamic>>('/api/v1/admin/settings');
    return AppSettings.fromJson(data);
  }

  Future<AppSettings> updateSettings(AppSettings settings) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/admin/settings',
      body: settings.toJson(),
    );
    return AppSettings.fromJson(data);
  }

  Future<List<AdminItem>> items() async {
    final data =
        await _client.get<List<dynamic>>('/api/v1/admin/items');
    return data
        .map((e) => AdminItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminItem> createItem(AdminItemRequest request) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/admin/items',
      body: request.toJson(),
    );
    return AdminItem.fromJson(data);
  }

  Future<AdminItem> updateItem(String id, AdminItemRequest request) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/admin/items/$id',
      body: request.toJson(),
    );
    return AdminItem.fromJson(data);
  }

  Future<void> deleteItem(String id) async {
    await _client.delete('/api/v1/admin/items/$id');
  }

  Future<List<AdminMenu>> menus() async {
    final data =
        await _client.get<List<dynamic>>('/api/v1/admin/menus');
    return data
        .map((e) => AdminMenu.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminMenu> createMenu({required String menuTitle, String imageUrl = ''}) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/admin/menus',
      body: {'menu_title': menuTitle, 'image_url': imageUrl},
    );
    return AdminMenu.fromJson(data);
  }

  Future<void> deleteMenu(int id) async {
    await _client.delete('/api/v1/admin/menus/$id');
  }

  Future<List<AdminDeal>> deals() async {
    final data =
        await _client.get<List<dynamic>>('/api/v1/admin/deals');
    return data
        .map((e) => AdminDeal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminDeal> createDeal(AdminDealRequest request) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/api/v1/admin/deals',
      body: request.toJson(),
    );
    return AdminDeal.fromJson(data);
  }

  Future<AdminDeal> updateDeal(int id, AdminDealRequest request) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/admin/deals/$id',
      body: request.toJson(),
    );
    return AdminDeal.fromJson(data);
  }

  Future<void> deleteDeal(int id) async {
    await _client.delete('/api/v1/admin/deals/$id');
  }

  Future<List<Page>> pages() async {
    final data =
        await _client.get<List<dynamic>>('/api/v1/admin/pages');
    return data
        .map((e) => Page.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Page> updatePage({
    required String slug,
    required String title,
    required String content,
  }) async {
    final data = await _client.put<Map<String, dynamic>>(
      '/api/v1/admin/pages/$slug',
      body: {'slug': slug, 'title': title, 'content': content},
    );
    return Page.fromJson(data);
  }

  Future<void> deletePage(int id) async {
    await _client.delete('/api/v1/admin/pages/$id');
  }
}
