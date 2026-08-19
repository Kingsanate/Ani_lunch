import 'package:supabase_flutter/supabase_flutter.dart';

class MenuService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMenus() async {
    final data = await _client.from('menus').select().order('menu_title');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final data = await _client.from('items').select().order('item_title');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> fetchDailyDeals() async {
    final data = await _client
        .from('daily_deals')
        .select()
        .eq('is_active', true)
        .order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> fetchAppSettings() async {
    return await _client.from('app_settings').select().maybeSingle();
  }

  RealtimeChannel subscribeToMenuChanges(void Function() callback) {
    return _client
        .channel('public:menu_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (_) => callback(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'menus',
          callback: (_) => callback(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_deals',
          callback: (_) => callback(),
        )
        .subscribe();
  }
}
