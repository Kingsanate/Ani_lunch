import '../money.dart';

class Item {
  final String id;
  final String? vendorId;
  final String name;
  final String? description;
  final Money price;
  final Money? originalPrice;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final int preparationMin;
  final double rating;
  final int reviewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.preparationMin,
    required this.rating,
    required this.reviewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: str(json, 'id'),
        vendorId: optStr(json, 'vendor_id'),
        name: str(json, 'name'),
        description: optStr(json, 'description'),
        price: Money.fromJson(json['price']),
        originalPrice: json['original_price'] == null
            ? null
            : Money.fromJson(json['original_price']),
        category: str(json, 'category'),
        imageUrl: optStr(json, 'image_url'),
        isAvailable: boolOf(json, 'is_available', true),
        preparationMin: intOf(json, 'preparation_min'),
        rating: doubleOf(json, 'rating'),
        reviewsCount: intOf(json, 'reviews_count'),
        createdAt: dateTimeOf(json, 'created_at'),
        updatedAt: dateTimeOf(json, 'updated_at'),
      );
}

class Menu {
  final String id;
  final String menuTitle;
  final String? imageUrl;
  final DateTime createdAt;

  const Menu({
    required this.id,
    required this.menuTitle,
    this.imageUrl,
    required this.createdAt,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        id: str(json, 'id'),
        menuTitle: str(json, 'menu_title'),
        imageUrl: optStr(json, 'image_url'),
        createdAt: dateTimeOf(json, 'created_at'),
      );
}

class DailyDeal {
  final String id;
  final String title;
  final String? description;
  final double discountPercent;
  final Money? maxDiscountAmount;
  final String? bannerImageUrl;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;

  const DailyDeal({
    required this.id,
    required this.title,
    this.description,
    required this.discountPercent,
    this.maxDiscountAmount,
    this.bannerImageUrl,
    required this.validFrom,
    required this.validUntil,
    required this.isActive,
  });

  factory DailyDeal.fromJson(Map<String, dynamic> json) => DailyDeal(
        id: str(json, 'id'),
        title: str(json, 'title'),
        description: optStr(json, 'description'),
        discountPercent: doubleOf(json, 'discount_percent'),
        maxDiscountAmount: json['max_discount_amount'] == null
            ? null
            : Money.fromJson(json['max_discount_amount']),
        bannerImageUrl: optStr(json, 'banner_image_url'),
        validFrom: dateTimeOf(json, 'valid_from'),
        validUntil: dateTimeOf(json, 'valid_until'),
        isActive: boolOf(json, 'is_active'),
      );
}
