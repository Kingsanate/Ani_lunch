import '../money.dart';

class AdminOrder {
  final String id;
  final String userId;
  final String vendorId;
  final String status;
  final List<AdminOrderItem> items;
  final Money subtotal;
  final Money deliveryFee;
  final Money discount;
  final Money totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String specialNotes;
  final String? riderId;
  final DateTime orderTime;
  final String customerName;
  final String address;

  const AdminOrder({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.specialNotes = '',
    this.riderId,
    required this.orderTime,
    this.customerName = '',
    this.address = '',
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) => AdminOrder(
        id: str(json, 'id'),
        userId: str(json, 'user_id'),
        vendorId: str(json, 'vendor_id'),
        status: str(json, 'status'),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => AdminOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: Money.fromJson(json['subtotal']),
        deliveryFee: Money.fromJson(json['delivery_fee']),
        discount: Money.fromJson(json['discount']),
        totalAmount: Money.fromJson(json['total_amount']),
        paymentMethod: str(json, 'payment_method'),
        paymentStatus: str(json, 'payment_status'),
        specialNotes: str(json, 'special_notes'),
        riderId: optStr(json, 'rider_id'),
        orderTime: dateTimeOf(json, 'order_time'),
        customerName: str(json, 'customer_name'),
        address: str(json, 'address'),
      );
}

class AdminOrderItem {
  final String id;
  final String itemId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money subtotal;

  const AdminOrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) =>
      AdminOrderItem(
        id: str(json, 'id'),
        itemId: str(json, 'item_id'),
        name: str(json, 'name'),
        quantity: intOf(json, 'quantity'),
        unitPrice: Money.fromJson(json['unit_price']),
        subtotal: Money.fromJson(json['subtotal']),
      );
}

class AdminUser {
  final String id;
  final String name;
  final String email;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: str(json, 'id'),
        name: str(json, 'name'),
        email: str(json, 'email'),
      );
}

class AdminRider {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isOnline;
  final bool isApproved;
  final String approvalStatus;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminRider({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isOnline,
    required this.isApproved,
    required this.approvalStatus,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminRider.fromJson(Map<String, dynamic> json) => AdminRider(
        id: str(json, 'id'),
        name: str(json, 'name'),
        phone: str(json, 'phone'),
        email: str(json, 'email'),
        isOnline: boolOf(json, 'is_online'),
        isApproved: boolOf(json, 'is_approved'),
        approvalStatus: str(json, 'approval_status'),
        rejectionReason: optStr(json, 'rejection_reason'),
        createdAt: dateTimeOf(json, 'created_at'),
        updatedAt: dateTimeOf(json, 'updated_at'),
      );
}

class AppSettings {
  final int id;
  final String? homeVideoUrl;
  final bool showHeroBanner;
  final String heroBadgeText;
  final String heroTitle;
  final String heroSubtitle;
  final String heroButtonText;
  final String footerSubtitle;
  final String footerSupportLinks;
  final String footerLegalLinks;
  final String footerCopyright;
  final DateTime? updatedAt;

  const AppSettings({
    required this.id,
    this.homeVideoUrl,
    required this.showHeroBanner,
    required this.heroBadgeText,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroButtonText,
    required this.footerSubtitle,
    required this.footerSupportLinks,
    required this.footerLegalLinks,
    required this.footerCopyright,
    this.updatedAt,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        id: intOf(json, 'id'),
        homeVideoUrl: optStr(json, 'home_video_url'),
        showHeroBanner: boolOf(json, 'show_hero_banner'),
        heroBadgeText: str(json, 'hero_badge_text'),
        heroTitle: str(json, 'hero_title'),
        heroSubtitle: str(json, 'hero_subtitle'),
        heroButtonText: str(json, 'hero_button_text'),
        footerSubtitle: str(json, 'footer_subtitle'),
        footerSupportLinks: str(json, 'footer_support_links'),
        footerLegalLinks: str(json, 'footer_legal_links'),
        footerCopyright: str(json, 'footer_copyright'),
        updatedAt: json['updated_at'] is String
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'home_video_url': homeVideoUrl,
        'show_hero_banner': showHeroBanner,
        'hero_badge_text': heroBadgeText,
        'hero_title': heroTitle,
        'hero_subtitle': heroSubtitle,
        'hero_button_text': heroButtonText,
        'footer_subtitle': footerSubtitle,
        'footer_support_links': footerSupportLinks,
        'footer_legal_links': footerLegalLinks,
        'footer_copyright': footerCopyright,
      };
}

class AdminItem {
  final String id;
  final String itemTitle;
  final Money price;
  final Money? originalPrice;
  final String description;
  final String? thumbnailUrl;
  final int? categoryId;
  final String? vendorId;
  final bool isActive;
  final int preparationMin;
  final double rating;
  final int reviewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminItem({
    required this.id,
    required this.itemTitle,
    required this.price,
    this.originalPrice,
    required this.description,
    this.thumbnailUrl,
    this.categoryId,
    this.vendorId,
    required this.isActive,
    required this.preparationMin,
    required this.rating,
    required this.reviewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminItem.fromJson(Map<String, dynamic> json) => AdminItem(
        id: str(json, 'id'),
        itemTitle: str(json, 'item_title'),
        price: Money.fromJson(json['price']),
        originalPrice: json['original_price'] == null
            ? null
            : Money.fromJson(json['original_price']),
        description: str(json, 'description'),
        thumbnailUrl: optStr(json, 'thumbnail_url'),
        categoryId: json['category_id'] is num
            ? (json['category_id'] as num).toInt()
            : null,
        vendorId: optStr(json, 'vendor_id'),
        isActive: boolOf(json, 'is_active'),
        preparationMin: intOf(json, 'preparation_min'),
        rating: doubleOf(json, 'rating'),
        reviewsCount: intOf(json, 'reviews_count'),
        createdAt: dateTimeOf(json, 'created_at'),
        updatedAt: dateTimeOf(json, 'updated_at'),
      );
}

class AdminItemRequest {
  final String itemTitle;
  final int price;
  final int? originalPrice;
  final String description;
  final String thumbnailUrl;
  final int? categoryId;
  final String? vendorId;
  final bool? isActive;
  final int? preparationMin;

  const AdminItemRequest({
    required this.itemTitle,
    required this.price,
    this.originalPrice,
    this.description = '',
    this.thumbnailUrl = '',
    this.categoryId,
    this.vendorId,
    this.isActive,
    this.preparationMin,
  });

  Map<String, dynamic> toJson() => {
        'item_title': itemTitle,
        'price': price,
        'original_price': originalPrice,
        'description': description,
        'thumbnail_url': thumbnailUrl,
        'category_id': categoryId,
        'vendor_id': vendorId,
        'is_active': isActive,
        'preparation_min': preparationMin,
      };
}

class AdminMenu {
  final int id;
  final String menuTitle;
  final String imageUrl;
  final DateTime createdAt;

  const AdminMenu({
    required this.id,
    required this.menuTitle,
    required this.imageUrl,
    required this.createdAt,
  });

  factory AdminMenu.fromJson(Map<String, dynamic> json) => AdminMenu(
        id: intOf(json, 'id'),
        menuTitle: str(json, 'menu_title'),
        imageUrl: str(json, 'image_url'),
        createdAt: dateTimeOf(json, 'created_at'),
      );
}

class AdminDeal {
  final int id;
  final String title;
  final String description;
  final Money originalPrice;
  final Money dealPrice;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  const AdminDeal({
    required this.id,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.dealPrice,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminDeal.fromJson(Map<String, dynamic> json) => AdminDeal(
        id: intOf(json, 'id'),
        title: str(json, 'title'),
        description: str(json, 'description'),
        originalPrice: Money.fromJson(json['original_price']),
        dealPrice: Money.fromJson(json['deal_price']),
        imageUrl: str(json, 'image_url'),
        isActive: boolOf(json, 'is_active'),
        createdAt: dateTimeOf(json, 'created_at'),
      );
}

class AdminDealRequest {
  final String title;
  final String description;
  final int originalPrice;
  final int dealPrice;
  final String imageUrl;
  final bool? isActive;

  const AdminDealRequest({
    required this.title,
    this.description = '',
    required this.originalPrice,
    required this.dealPrice,
    this.imageUrl = '',
    this.isActive,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'original_price': originalPrice,
        'deal_price': dealPrice,
        'image_url': imageUrl,
        'is_active': isActive,
      };
}

class Page {
  final int id;
  final String slug;
  final String title;
  final String content;
  final DateTime updatedAt;

  const Page({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  factory Page.fromJson(Map<String, dynamic> json) => Page(
        id: intOf(json, 'id'),
        slug: str(json, 'slug'),
        title: str(json, 'title'),
        content: str(json, 'content'),
        updatedAt: dateTimeOf(json, 'updated_at'),
      );
}

class PageRequest {
  final String slug;
  final String title;
  final String content;

  const PageRequest({
    required this.slug,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'title': title,
        'content': content,
      };
}

class DashboardStats {
  final int ordersToday;
  final Money revenueToday;
  final int totalOrders;
  final int activeRiders;
  final int pendingRiderApprovals;
  final int vendorCount;
  final int itemCount;
  final int userCount;
  final Map<String, int> statusBreakdown;

  const DashboardStats({
    required this.ordersToday,
    required this.revenueToday,
    required this.totalOrders,
    required this.activeRiders,
    required this.pendingRiderApprovals,
    required this.vendorCount,
    required this.itemCount,
    required this.userCount,
    required this.statusBreakdown,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        ordersToday: intOf(json, 'orders_today'),
        revenueToday: Money.fromJson(json['revenue_today']),
        totalOrders: intOf(json, 'total_orders'),
        activeRiders: intOf(json, 'active_riders'),
        pendingRiderApprovals: intOf(json, 'pending_rider_approvals'),
        vendorCount: intOf(json, 'vendor_count'),
        itemCount: intOf(json, 'item_count'),
        userCount: intOf(json, 'user_count'),
        statusBreakdown: (json['status_breakdown'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );
}
