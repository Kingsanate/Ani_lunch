import 'package:supabase_flutter/supabase_flutter.dart';

class LunchService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getLunchProducts() async {
    final response = await _client
        .from('meal_products')
        .select()
        .eq('is_available', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getLunchById(String id) async {
    final response = await _client
        .from('meal_products')
        .select()
        .eq('id', id)
        .single();
    return response;
  }

  // Future integration point for saving cart items to backend if needed.
  Future<void> addToCart(Map<String, dynamic> product) async {
    // Currently handled in state by LunchProvider as requested.
  }
}
