import 'package:anilunch_core/anilunch_core.dart' hide ApiClient;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/api_provider.dart';

/// ApiClient talks to the Go backend with the Go-issued access token (minted
/// via /auth/exchange). Every method falls back to the legacy Supabase path
/// when the backend is unreachable.
class ApiClient {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static AnilunchApi get _api => AniApi.instance.api;

  // ── Orders ────────────────────────────────────────────────────────────────

  /// Server-authoritative status transition (confirmed, cancelled, ...).
  static Future<bool> transitionOrder(String orderId, String status) async {
    try {
      await _api.orders.transition(orderId, status);
      return true;
    } catch (e) {
      debugPrint('ApiClient.transitionOrder error: $e');
      return false;
    }
  }

  /// All orders (optionally filtered by status), mapped to the legacy shape.
  static Future<List<Map<String, dynamic>>> fetchOrders({
    String? status,
  }) async {
    try {
      final orders = await _api.admin.orders(status: status);
      return orders.map(_toLegacyOrder).toList();
    } catch (e) {
      debugPrint('ApiClient.fetchOrders error: $e');
    }
    try {
      final res = await _supabase
          .from('orders')
          .select()
          .order('order_time', ascending: false);
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiClient.fetchOrders (supabase) error: $e');
      return [];
    }
  }

  /// Customer records for the order console.
  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final users = await _api.admin.users();
      return users
          .map((u) => <String, dynamic>{
                'id': u.id,
                'name': u.name,
                'email': u.email,
              })
          .toList();
    } catch (e) {
      debugPrint('ApiClient.fetchUsers error: $e');
    }
    try {
      final res =
          await _supabase.from('users').select('id, name, email');
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiClient.fetchUsers (supabase) error: $e');
      return [];
    }
  }

  // ── Riders ────────────────────────────────────────────────────────────────

  /// Approves or rejects a rider application.
  static Future<bool> setRiderApproval(
    String riderId,
    String approvalStatus, {
    String? rejectionReason,
  }) async {
    try {
      await _api.admin.setRiderApproval(
        riderId,
        approvalStatus: approvalStatus,
        rejectionReason: rejectionReason,
      );
      return true;
    } catch (e) {
      debugPrint('ApiClient.setRiderApproval error: $e');
      return false;
    }
  }

  /// Rider records, mapped to the legacy shape.
  static Future<List<Map<String, dynamic>>> fetchRiders({
    String? status,
  }) async {
    try {
      final riders = await _api.admin.riders(status: status);
      return riders.map((r) => <String, dynamic>{
        'id': r.id,
        'name': r.name,
        'phone': r.phone,
        'email': r.email,
        'is_online': r.isOnline,
        'is_approved': r.isApproved,
        'approval_status': r.approvalStatus,
        'rejection_reason': r.rejectionReason,
        'created_at': r.createdAt.toIso8601String(),
      }).toList();
    } catch (e) {
      debugPrint('ApiClient.fetchRiders error: $e');
    }
    try {
      var query = _supabase.from('riders').select();
      if (status != null) query = query.eq('approval_status', status);
      final res = await query.order('created_at', ascending: false);
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiClient.fetchRiders (supabase) error: $e');
      return [];
    }
  }

  // ── Catalog (items / menus / deals) ───────────────────────────────────────

  /// Catalog items (including inactive), mapped to the legacy shape.
  static Future<List<Map<String, dynamic>>> fetchItems() async {
    try {
      final items = await _api.admin.items();
      return items.map((i) => <String, dynamic>{
        'id': i.id,
        'item_title': i.itemTitle,
        'item_price': i.price.paise / 100,
        'discount_price': (i.originalPrice?.paise ?? 0) / 100,
        'description': i.description,
        'thumbnail_url': i.thumbnailUrl,
        'category_id': i.categoryId,
        'vendor_id': i.vendorId,
        'is_active': i.isActive,
        'preparation_min': i.preparationMin,
        'rating': i.rating,
        'reviews_count': i.reviewsCount,
        'created_at': i.createdAt.toIso8601String(),
      }).toList();
    } catch (e) {
      debugPrint('ApiClient.fetchItems error: $e');
    }
    try {
      final res = await _supabase
          .from('items')
          .select('*, menus(menu_title)')
          .order('item_title');
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiClient.fetchItems (supabase) error: $e');
      return [];
    }
  }

  /// Menus / categories for the item editor.
  static Future<List<Map<String, dynamic>>> fetchMenus() async {
    try {
      final menus = await _api.admin.menus();
      return menus.map((m) => <String, dynamic>{
        'id': m.id,
        'menu_title': m.menuTitle,
        'image_url': m.imageUrl,
      }).toList();
    } catch (e) {
      debugPrint('ApiClient.fetchMenus error: $e');
    }
    try {
      final res = await _supabase.from('menus').select();
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiClient.fetchMenus (supabase) error: $e');
      return [];
    }
  }

  /// Creates or updates a catalog item; returns true on success.
  static Future<bool> saveItem(Map<String, dynamic> data) async {
    final id = data['id'] as String?;
    try {
      if (id != null && id.isNotEmpty) {
        await _api.admin.updateItem(id, _toItemRequest(data));
      } else {
        await _api.admin.createItem(_toItemRequest(data));
      }
      return true;
    } catch (e) {
      debugPrint('ApiClient.saveItem error: $e');
    }
    try {
      if (id != null && id.isNotEmpty) {
        await _supabase.from('items').update(data).eq('id', id);
      } else {
        await _supabase.from('items').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('ApiClient.saveItem (supabase) error: $e');
      return false;
    }
  }

  static Future<bool> deleteItem(String id) async {
    try {
      await _api.admin.deleteItem(id);
      return true;
    } catch (e) {
      debugPrint('ApiClient.deleteItem error: $e');
    }
    try {
      await _supabase.from('items').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('ApiClient.deleteItem (supabase) error: $e');
      return false;
    }
  }

  /// Daily deals, mapped to the legacy shape.
  static Future<List<Map<String, dynamic>>> fetchDeals() async {
    try {
      final deals = await _api.admin.deals();
      return deals.map((d) => <String, dynamic>{
        'id': d.id,
        'title': d.title,
        'description': d.description,
        'original_price': d.originalPrice.paise / 100,
        'deal_price': d.dealPrice.paise / 100,
        'image_url': d.imageUrl,
        'is_active': d.isActive,
        'created_at': d.createdAt.toIso8601String(),
      }).toList();
    } catch (e) {
      debugPrint('ApiClient.fetchDeals error: $e');
    }
    try {
      final res = await _supabase
          .from('daily_deals')
          .select()
          .order('created_at');
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiClient.fetchDeals (supabase) error: $e');
      return [];
    }
  }

  static Future<bool> saveDeal(Map<String, dynamic> data) async {
    final rawId = data['id'];
    try {
      if (rawId != null) {
        await _api.admin.updateDeal(rawId as int, _toDealRequest(data));
      } else {
        await _api.admin.createDeal(_toDealRequest(data));
      }
      return true;
    } catch (e) {
      debugPrint('ApiClient.saveDeal error: $e');
    }
    try {
      if (rawId != null) {
        await _supabase.from('daily_deals').update(data).eq('id', rawId);
      } else {
        await _supabase.from('daily_deals').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('ApiClient.saveDeal (supabase) error: $e');
      return false;
    }
  }

  static Future<bool> deleteDeal(int id) async {
    try {
      await _api.admin.deleteDeal(id);
      return true;
    } catch (e) {
      debugPrint('ApiClient.deleteDeal error: $e');
    }
    try {
      await _supabase.from('daily_deals').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('ApiClient.deleteDeal (supabase) error: $e');
      return false;
    }
  }

  // ── Settings & pages ──────────────────────────────────────────────────────

  /// App branding settings as a legacy map.
  static Future<Map<String, dynamic>?> fetchSettings() async {
    try {
      final s = await _api.admin.getSettings();
      return <String, dynamic>{
        'id': s.id,
        'home_video_url': s.homeVideoUrl,
        'show_hero_banner': s.showHeroBanner,
        'hero_badge_text': s.heroBadgeText,
        'hero_title': s.heroTitle,
        'hero_subtitle': s.heroSubtitle,
        'hero_button_text': s.heroButtonText,
        'footer_subtitle': s.footerSubtitle,
        'footer_support_links': s.footerSupportLinks,
        'footer_legal_links': s.footerLegalLinks,
        'footer_copyright': s.footerCopyright,
      };
    } catch (e) {
      debugPrint('ApiClient.fetchSettings error: $e');
    }
    try {
      return await _supabase.from('app_settings').select().maybeSingle();
    } catch (e) {
      debugPrint('ApiClient.fetchSettings (supabase) error: $e');
      return null;
    }
  }

  static Future<bool> saveSettings(Map<String, dynamic> data) async {
    try {
      final s = AppSettings(
        id: 1,
        homeVideoUrl: data['home_video_url'] as String?,
        showHeroBanner: data['show_hero_banner'] ?? false,
        heroBadgeText: data['hero_badge_text']?.toString() ?? '',
        heroTitle: data['hero_title']?.toString() ?? '',
        heroSubtitle: data['hero_subtitle']?.toString() ?? '',
        heroButtonText: data['hero_button_text']?.toString() ?? '',
        footerSubtitle: data['footer_subtitle']?.toString() ?? '',
        footerSupportLinks: data['footer_support_links']?.toString() ?? '',
        footerLegalLinks: data['footer_legal_links']?.toString() ?? '',
        footerCopyright: data['footer_copyright']?.toString() ?? '',
      );
      await _api.admin.updateSettings(s);
      return true;
    } catch (e) {
      debugPrint('ApiClient.saveSettings error: $e');
    }
    try {
      final id = data['id'];
      if (id != null) {
        await _supabase.from('app_settings').update(data).eq('id', id);
      } else {
        await _supabase.from('app_settings').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('ApiClient.saveSettings (supabase) error: $e');
      return false;
    }
  }

  /// CMS pages, mapped to the legacy shape.
  static Future<List<Map<String, dynamic>>> fetchPages() async {
    try {
      final pages = await _api.admin.pages();
      return pages.map((p) => <String, dynamic>{
        'id': p.id,
        'slug': p.slug,
        'title': p.title,
        'content': p.content,
        'updated_at': p.updatedAt.toIso8601String(),
      }).toList();
    } catch (e) {
      debugPrint('ApiClient.fetchPages error: $e');
    }
    try {
      final res = await _supabase
          .from('pages')
          .select()
          .order('created_at', ascending: false);
      return res.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('ApiClient.fetchPages (supabase) error: $e');
      return [];
    }
  }

  static Future<bool> savePage(Map<String, dynamic> data) async {
    try {
      await _api.admin.updatePage(
        slug: data['slug']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        content: data['content']?.toString() ?? '',
      );
      return true;
    } catch (e) {
      debugPrint('ApiClient.savePage error: $e');
    }
    try {
      final id = data['id'];
      if (id != null) {
        await _supabase.from('pages').update(data).eq('id', id);
      } else {
        await _supabase.from('pages').insert(data);
      }
      return true;
    } catch (e) {
      debugPrint('ApiClient.savePage (supabase) error: $e');
      return false;
    }
  }

  static Future<bool> deletePage(int id) async {
    try {
      await _api.admin.deletePage(id);
      return true;
    } catch (e) {
      debugPrint('ApiClient.deletePage error: $e');
    }
    try {
      await _supabase.from('pages').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('ApiClient.deletePage (supabase) error: $e');
      return false;
    }
  }

  // ── Shape mappers ─────────────────────────────────────────────────────────

  static Map<String, dynamic> _toLegacyOrder(AdminOrder o) => {
        'id': o.id,
        'order_time': o.orderTime.toIso8601String(),
        'status': o.status,
        'ordered_by': o.customerName.isNotEmpty ? o.customerName : 'Customer',
        'items': o.items
            .map((i) => {
                  'qty': i.quantity,
                  'name': i.name,
                  'price': i.unitPrice.paise / 100,
                })
            .toList(),
        'total_amount': o.totalAmount.paise / 100,
        'address': o.address,
        'user_id': o.userId,
        'vendor_id': o.vendorId,
        'payment_method': o.paymentMethod,
        'special_notes': o.specialNotes,
      };

  static AdminItemRequest _toItemRequest(Map<String, dynamic> data) {
    final price = (data['item_price'] as num?)?.toDouble() ?? 0;
    final discount = (data['discount_price'] as num?)?.toDouble();
    return AdminItemRequest(
      itemTitle: data['item_title']?.toString() ?? '',
      price: (price * 100).round(),
      originalPrice: discount == null || discount <= 0
          ? null
          : (discount * 100).round(),
      description: data['description']?.toString() ?? '',
      thumbnailUrl: data['thumbnail_url']?.toString() ?? '',
      categoryId: data['category_id'] is int
          ? (data['category_id'] as int?)?.toInt()
          : int.tryParse(data['category_id']?.toString() ?? ''),
      vendorId: data['vendor_id']?.toString(),
      isActive: data['is_active'] as bool?,
      preparationMin: (data['preparation_min'] as int?) ?? 20,
    );
  }

  static AdminDealRequest _toDealRequest(Map<String, dynamic> data) {
    final original =
        ((data['original_price'] as num?)?.toDouble() ?? 0) * 100;
    final deal = ((data['deal_price'] as num?)?.toDouble() ?? 0) * 100;
    return AdminDealRequest(
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      originalPrice: original.round(),
      dealPrice: deal.round(),
      imageUrl: data['image_url']?.toString() ?? '',
      isActive: data['is_active'] as bool?,
    );
  }
}