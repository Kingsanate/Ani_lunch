// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalItemsTable extends LocalItems
    with TableInfo<$LocalItemsTable, LocalItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorIdMeta = const VerificationMeta(
    'vendorId',
  );
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
    'vendor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<BigInt> price = GeneratedColumn<BigInt>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPriceMeta = const VerificationMeta(
    'originalPrice',
  );
  @override
  late final GeneratedColumn<BigInt> originalPrice = GeneratedColumn<BigInt>(
    'original_price',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _prepTimeMeta = const VerificationMeta(
    'prepTime',
  );
  @override
  late final GeneratedColumn<int> prepTime = GeneratedColumn<int>(
    'prep_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(4.5),
  );
  static const VerificationMeta _reviewsCountMeta = const VerificationMeta(
    'reviewsCount',
  );
  @override
  late final GeneratedColumn<int> reviewsCount = GeneratedColumn<int>(
    'reviews_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    vendorId,
    name,
    description,
    price,
    originalPrice,
    category,
    imageUrl,
    isAvailable,
    prepTime,
    rating,
    reviewsCount,
    syncedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('original_price')) {
      context.handle(
        _originalPriceMeta,
        originalPrice.isAcceptableOrUnknown(
          data['original_price']!,
          _originalPriceMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('prep_time')) {
      context.handle(
        _prepTimeMeta,
        prepTime.isAcceptableOrUnknown(data['prep_time']!, _prepTimeMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('reviews_count')) {
      context.handle(
        _reviewsCountMeta,
        reviewsCount.isAcceptableOrUnknown(
          data['reviews_count']!,
          _reviewsCountMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      vendorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}price'],
      )!,
      originalPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}original_price'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      prepTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_time'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      reviewsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviews_count'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalItemsTable createAlias(String alias) {
    return $LocalItemsTable(attachedDatabase, alias);
  }
}

class LocalItem extends DataClass implements Insertable<LocalItem> {
  final String id;
  final String? vendorId;
  final String name;
  final String? description;
  final BigInt price;
  final BigInt? originalPrice;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final int prepTime;
  final double rating;
  final int reviewsCount;
  final DateTime syncedAt;
  final DateTime updatedAt;
  const LocalItem({
    required this.id,
    this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.prepTime,
    required this.rating,
    required this.reviewsCount,
    required this.syncedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || vendorId != null) {
      map['vendor_id'] = Variable<String>(vendorId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<BigInt>(price);
    if (!nullToAbsent || originalPrice != null) {
      map['original_price'] = Variable<BigInt>(originalPrice);
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['is_available'] = Variable<bool>(isAvailable);
    map['prep_time'] = Variable<int>(prepTime);
    map['rating'] = Variable<double>(rating);
    map['reviews_count'] = Variable<int>(reviewsCount);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalItemsCompanion(
      id: Value(id),
      vendorId: vendorId == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
      originalPrice: originalPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPrice),
      category: Value(category),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      isAvailable: Value(isAvailable),
      prepTime: Value(prepTime),
      rating: Value(rating),
      reviewsCount: Value(reviewsCount),
      syncedAt: Value(syncedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalItem(
      id: serializer.fromJson<String>(json['id']),
      vendorId: serializer.fromJson<String?>(json['vendorId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<BigInt>(json['price']),
      originalPrice: serializer.fromJson<BigInt?>(json['originalPrice']),
      category: serializer.fromJson<String>(json['category']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      prepTime: serializer.fromJson<int>(json['prepTime']),
      rating: serializer.fromJson<double>(json['rating']),
      reviewsCount: serializer.fromJson<int>(json['reviewsCount']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vendorId': serializer.toJson<String?>(vendorId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<BigInt>(price),
      'originalPrice': serializer.toJson<BigInt?>(originalPrice),
      'category': serializer.toJson<String>(category),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'prepTime': serializer.toJson<int>(prepTime),
      'rating': serializer.toJson<double>(rating),
      'reviewsCount': serializer.toJson<int>(reviewsCount),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalItem copyWith({
    String? id,
    Value<String?> vendorId = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    BigInt? price,
    Value<BigInt?> originalPrice = const Value.absent(),
    String? category,
    Value<String?> imageUrl = const Value.absent(),
    bool? isAvailable,
    int? prepTime,
    double? rating,
    int? reviewsCount,
    DateTime? syncedAt,
    DateTime? updatedAt,
  }) => LocalItem(
    id: id ?? this.id,
    vendorId: vendorId.present ? vendorId.value : this.vendorId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    price: price ?? this.price,
    originalPrice: originalPrice.present
        ? originalPrice.value
        : this.originalPrice,
    category: category ?? this.category,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    isAvailable: isAvailable ?? this.isAvailable,
    prepTime: prepTime ?? this.prepTime,
    rating: rating ?? this.rating,
    reviewsCount: reviewsCount ?? this.reviewsCount,
    syncedAt: syncedAt ?? this.syncedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalItem copyWithCompanion(LocalItemsCompanion data) {
    return LocalItem(
      id: data.id.present ? data.id.value : this.id,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      price: data.price.present ? data.price.value : this.price,
      originalPrice: data.originalPrice.present
          ? data.originalPrice.value
          : this.originalPrice,
      category: data.category.present ? data.category.value : this.category,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      prepTime: data.prepTime.present ? data.prepTime.value : this.prepTime,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewsCount: data.reviewsCount.present
          ? data.reviewsCount.value
          : this.reviewsCount,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalItem(')
          ..write('id: $id, ')
          ..write('vendorId: $vendorId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('category: $category, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('prepTime: $prepTime, ')
          ..write('rating: $rating, ')
          ..write('reviewsCount: $reviewsCount, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    vendorId,
    name,
    description,
    price,
    originalPrice,
    category,
    imageUrl,
    isAvailable,
    prepTime,
    rating,
    reviewsCount,
    syncedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalItem &&
          other.id == this.id &&
          other.vendorId == this.vendorId &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price &&
          other.originalPrice == this.originalPrice &&
          other.category == this.category &&
          other.imageUrl == this.imageUrl &&
          other.isAvailable == this.isAvailable &&
          other.prepTime == this.prepTime &&
          other.rating == this.rating &&
          other.reviewsCount == this.reviewsCount &&
          other.syncedAt == this.syncedAt &&
          other.updatedAt == this.updatedAt);
}

class LocalItemsCompanion extends UpdateCompanion<LocalItem> {
  final Value<String> id;
  final Value<String?> vendorId;
  final Value<String> name;
  final Value<String?> description;
  final Value<BigInt> price;
  final Value<BigInt?> originalPrice;
  final Value<String> category;
  final Value<String?> imageUrl;
  final Value<bool> isAvailable;
  final Value<int> prepTime;
  final Value<double> rating;
  final Value<int> reviewsCount;
  final Value<DateTime> syncedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalItemsCompanion({
    this.id = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
    this.originalPrice = const Value.absent(),
    this.category = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewsCount = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalItemsCompanion.insert({
    required String id,
    this.vendorId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required BigInt price,
    this.originalPrice = const Value.absent(),
    required String category,
    this.imageUrl = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.prepTime = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewsCount = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       price = Value(price),
       category = Value(category);
  static Insertable<LocalItem> custom({
    Expression<String>? id,
    Expression<String>? vendorId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<BigInt>? price,
    Expression<BigInt>? originalPrice,
    Expression<String>? category,
    Expression<String>? imageUrl,
    Expression<bool>? isAvailable,
    Expression<int>? prepTime,
    Expression<double>? rating,
    Expression<int>? reviewsCount,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vendorId != null) 'vendor_id': vendorId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
      if (originalPrice != null) 'original_price': originalPrice,
      if (category != null) 'category': category,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isAvailable != null) 'is_available': isAvailable,
      if (prepTime != null) 'prep_time': prepTime,
      if (rating != null) 'rating': rating,
      if (reviewsCount != null) 'reviews_count': reviewsCount,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? vendorId,
    Value<String>? name,
    Value<String?>? description,
    Value<BigInt>? price,
    Value<BigInt?>? originalPrice,
    Value<String>? category,
    Value<String?>? imageUrl,
    Value<bool>? isAvailable,
    Value<int>? prepTime,
    Value<double>? rating,
    Value<int>? reviewsCount,
    Value<DateTime>? syncedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalItemsCompanion(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      prepTime: prepTime ?? this.prepTime,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      syncedAt: syncedAt ?? this.syncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<BigInt>(price.value);
    }
    if (originalPrice.present) {
      map['original_price'] = Variable<BigInt>(originalPrice.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (prepTime.present) {
      map['prep_time'] = Variable<int>(prepTime.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (reviewsCount.present) {
      map['reviews_count'] = Variable<int>(reviewsCount.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalItemsCompanion(')
          ..write('id: $id, ')
          ..write('vendorId: $vendorId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('category: $category, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('prepTime: $prepTime, ')
          ..write('rating: $rating, ')
          ..write('reviewsCount: $reviewsCount, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCartItemsTable extends LocalCartItems
    with TableInfo<$LocalCartItemsTable, LocalCartItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCartItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<BigInt> price = GeneratedColumn<BigInt>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedSpiceMeta = const VerificationMeta(
    'selectedSpice',
  );
  @override
  late final GeneratedColumn<String> selectedSpice = GeneratedColumn<String>(
    'selected_spice',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedPortionMeta = const VerificationMeta(
    'selectedPortion',
  );
  @override
  late final GeneratedColumn<String> selectedPortion = GeneratedColumn<String>(
    'selected_portion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialNotesMeta = const VerificationMeta(
    'specialNotes',
  );
  @override
  late final GeneratedColumn<String> specialNotes = GeneratedColumn<String>(
    'special_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    name,
    price,
    quantity,
    imageUrl,
    selectedSpice,
    selectedPortion,
    specialNotes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cart_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCartItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('selected_spice')) {
      context.handle(
        _selectedSpiceMeta,
        selectedSpice.isAcceptableOrUnknown(
          data['selected_spice']!,
          _selectedSpiceMeta,
        ),
      );
    }
    if (data.containsKey('selected_portion')) {
      context.handle(
        _selectedPortionMeta,
        selectedPortion.isAcceptableOrUnknown(
          data['selected_portion']!,
          _selectedPortionMeta,
        ),
      );
    }
    if (data.containsKey('special_notes')) {
      context.handle(
        _specialNotesMeta,
        specialNotes.isAcceptableOrUnknown(
          data['special_notes']!,
          _specialNotesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCartItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCartItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      selectedSpice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_spice'],
      ),
      selectedPortion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_portion'],
      ),
      specialNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}special_notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalCartItemsTable createAlias(String alias) {
    return $LocalCartItemsTable(attachedDatabase, alias);
  }
}

class LocalCartItem extends DataClass implements Insertable<LocalCartItem> {
  final String id;
  final String itemId;
  final String name;
  final BigInt price;
  final int quantity;
  final String? imageUrl;
  final String? selectedSpice;
  final String? selectedPortion;
  final String? specialNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalCartItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.selectedSpice,
    this.selectedPortion,
    this.specialNotes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<BigInt>(price);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || selectedSpice != null) {
      map['selected_spice'] = Variable<String>(selectedSpice);
    }
    if (!nullToAbsent || selectedPortion != null) {
      map['selected_portion'] = Variable<String>(selectedPortion);
    }
    if (!nullToAbsent || specialNotes != null) {
      map['special_notes'] = Variable<String>(specialNotes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalCartItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalCartItemsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      name: Value(name),
      price: Value(price),
      quantity: Value(quantity),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      selectedSpice: selectedSpice == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedSpice),
      selectedPortion: selectedPortion == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedPortion),
      specialNotes: specialNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(specialNotes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCartItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCartItem(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<BigInt>(json['price']),
      quantity: serializer.fromJson<int>(json['quantity']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      selectedSpice: serializer.fromJson<String?>(json['selectedSpice']),
      selectedPortion: serializer.fromJson<String?>(json['selectedPortion']),
      specialNotes: serializer.fromJson<String?>(json['specialNotes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<BigInt>(price),
      'quantity': serializer.toJson<int>(quantity),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'selectedSpice': serializer.toJson<String?>(selectedSpice),
      'selectedPortion': serializer.toJson<String?>(selectedPortion),
      'specialNotes': serializer.toJson<String?>(specialNotes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCartItem copyWith({
    String? id,
    String? itemId,
    String? name,
    BigInt? price,
    int? quantity,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> selectedSpice = const Value.absent(),
    Value<String?> selectedPortion = const Value.absent(),
    Value<String?> specialNotes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalCartItem(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    name: name ?? this.name,
    price: price ?? this.price,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    selectedSpice: selectedSpice.present
        ? selectedSpice.value
        : this.selectedSpice,
    selectedPortion: selectedPortion.present
        ? selectedPortion.value
        : this.selectedPortion,
    specialNotes: specialNotes.present ? specialNotes.value : this.specialNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalCartItem copyWithCompanion(LocalCartItemsCompanion data) {
    return LocalCartItem(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      selectedSpice: data.selectedSpice.present
          ? data.selectedSpice.value
          : this.selectedSpice,
      selectedPortion: data.selectedPortion.present
          ? data.selectedPortion.value
          : this.selectedPortion,
      specialNotes: data.specialNotes.present
          ? data.specialNotes.value
          : this.specialNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCartItem(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('selectedSpice: $selectedSpice, ')
          ..write('selectedPortion: $selectedPortion, ')
          ..write('specialNotes: $specialNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    name,
    price,
    quantity,
    imageUrl,
    selectedSpice,
    selectedPortion,
    specialNotes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCartItem &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.name == this.name &&
          other.price == this.price &&
          other.quantity == this.quantity &&
          other.imageUrl == this.imageUrl &&
          other.selectedSpice == this.selectedSpice &&
          other.selectedPortion == this.selectedPortion &&
          other.specialNotes == this.specialNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalCartItemsCompanion extends UpdateCompanion<LocalCartItem> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> name;
  final Value<BigInt> price;
  final Value<int> quantity;
  final Value<String?> imageUrl;
  final Value<String?> selectedSpice;
  final Value<String?> selectedPortion;
  final Value<String?> specialNotes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalCartItemsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.quantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.selectedSpice = const Value.absent(),
    this.selectedPortion = const Value.absent(),
    this.specialNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCartItemsCompanion.insert({
    required String id,
    required String itemId,
    required String name,
    required BigInt price,
    this.quantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.selectedSpice = const Value.absent(),
    this.selectedPortion = const Value.absent(),
    this.specialNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       name = Value(name),
       price = Value(price);
  static Insertable<LocalCartItem> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? name,
    Expression<BigInt>? price,
    Expression<int>? quantity,
    Expression<String>? imageUrl,
    Expression<String>? selectedSpice,
    Expression<String>? selectedPortion,
    Expression<String>? specialNotes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
      if (imageUrl != null) 'image_url': imageUrl,
      if (selectedSpice != null) 'selected_spice': selectedSpice,
      if (selectedPortion != null) 'selected_portion': selectedPortion,
      if (specialNotes != null) 'special_notes': specialNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCartItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? name,
    Value<BigInt>? price,
    Value<int>? quantity,
    Value<String?>? imageUrl,
    Value<String?>? selectedSpice,
    Value<String?>? selectedPortion,
    Value<String?>? specialNotes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalCartItemsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      selectedSpice: selectedSpice ?? this.selectedSpice,
      selectedPortion: selectedPortion ?? this.selectedPortion,
      specialNotes: specialNotes ?? this.specialNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<BigInt>(price.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (selectedSpice.present) {
      map['selected_spice'] = Variable<String>(selectedSpice.value);
    }
    if (selectedPortion.present) {
      map['selected_portion'] = Variable<String>(selectedPortion.value);
    }
    if (specialNotes.present) {
      map['special_notes'] = Variable<String>(specialNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCartItemsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('selectedSpice: $selectedSpice, ')
          ..write('selectedPortion: $selectedPortion, ')
          ..write('specialNotes: $specialNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOrdersTable extends LocalOrders
    with TableInfo<$LocalOrdersTable, LocalOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vendorIdMeta = const VerificationMeta(
    'vendorId',
  );
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
    'vendor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _riderIdMeta = const VerificationMeta(
    'riderId',
  );
  @override
  late final GeneratedColumn<String> riderId = GeneratedColumn<String>(
    'rider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<BigInt> subtotal = GeneratedColumn<BigInt>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryFeeMeta = const VerificationMeta(
    'deliveryFee',
  );
  @override
  late final GeneratedColumn<BigInt> deliveryFee = GeneratedColumn<BigInt>(
    'delivery_fee',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<BigInt> discount = GeneratedColumn<BigInt>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultValue: Constant(BigInt.zero),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<BigInt> totalAmount = GeneratedColumn<BigInt>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _couponCodeMeta = const VerificationMeta(
    'couponCode',
  );
  @override
  late final GeneratedColumn<String> couponCode = GeneratedColumn<String>(
    'coupon_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cod'),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _deliveryStreetMeta = const VerificationMeta(
    'deliveryStreet',
  );
  @override
  late final GeneratedColumn<String> deliveryStreet = GeneratedColumn<String>(
    'delivery_street',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deliveryCityMeta = const VerificationMeta(
    'deliveryCity',
  );
  @override
  late final GeneratedColumn<String> deliveryCity = GeneratedColumn<String>(
    'delivery_city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deliveryZipMeta = const VerificationMeta(
    'deliveryZip',
  );
  @override
  late final GeneratedColumn<String> deliveryZip = GeneratedColumn<String>(
    'delivery_zip',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deliveryLatMeta = const VerificationMeta(
    'deliveryLat',
  );
  @override
  late final GeneratedColumn<double> deliveryLat = GeneratedColumn<double>(
    'delivery_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveryLngMeta = const VerificationMeta(
    'deliveryLng',
  );
  @override
  late final GeneratedColumn<double> deliveryLng = GeneratedColumn<double>(
    'delivery_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialNotesMeta = const VerificationMeta(
    'specialNotes',
  );
  @override
  late final GeneratedColumn<String> specialNotes = GeneratedColumn<String>(
    'special_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    vendorId,
    riderId,
    status,
    subtotal,
    deliveryFee,
    discount,
    totalAmount,
    couponCode,
    paymentMethod,
    paymentStatus,
    deliveryStreet,
    deliveryCity,
    deliveryZip,
    deliveryLat,
    deliveryLng,
    specialNotes,
    idempotencyKey,
    syncStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    }
    if (data.containsKey('rider_id')) {
      context.handle(
        _riderIdMeta,
        riderId.isAcceptableOrUnknown(data['rider_id']!, _riderIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('delivery_fee')) {
      context.handle(
        _deliveryFeeMeta,
        deliveryFee.isAcceptableOrUnknown(
          data['delivery_fee']!,
          _deliveryFeeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryFeeMeta);
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('coupon_code')) {
      context.handle(
        _couponCodeMeta,
        couponCode.isAcceptableOrUnknown(data['coupon_code']!, _couponCodeMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('delivery_street')) {
      context.handle(
        _deliveryStreetMeta,
        deliveryStreet.isAcceptableOrUnknown(
          data['delivery_street']!,
          _deliveryStreetMeta,
        ),
      );
    }
    if (data.containsKey('delivery_city')) {
      context.handle(
        _deliveryCityMeta,
        deliveryCity.isAcceptableOrUnknown(
          data['delivery_city']!,
          _deliveryCityMeta,
        ),
      );
    }
    if (data.containsKey('delivery_zip')) {
      context.handle(
        _deliveryZipMeta,
        deliveryZip.isAcceptableOrUnknown(
          data['delivery_zip']!,
          _deliveryZipMeta,
        ),
      );
    }
    if (data.containsKey('delivery_lat')) {
      context.handle(
        _deliveryLatMeta,
        deliveryLat.isAcceptableOrUnknown(
          data['delivery_lat']!,
          _deliveryLatMeta,
        ),
      );
    }
    if (data.containsKey('delivery_lng')) {
      context.handle(
        _deliveryLngMeta,
        deliveryLng.isAcceptableOrUnknown(
          data['delivery_lng']!,
          _deliveryLngMeta,
        ),
      );
    }
    if (data.containsKey('special_notes')) {
      context.handle(
        _specialNotesMeta,
        specialNotes.isAcceptableOrUnknown(
          data['special_notes']!,
          _specialNotesMeta,
        ),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      vendorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_id'],
      ),
      riderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rider_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}subtotal'],
      )!,
      deliveryFee: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}delivery_fee'],
      )!,
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}discount'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}total_amount'],
      )!,
      couponCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coupon_code'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      deliveryStreet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_street'],
      )!,
      deliveryCity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_city'],
      )!,
      deliveryZip: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_zip'],
      )!,
      deliveryLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}delivery_lat'],
      ),
      deliveryLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}delivery_lng'],
      ),
      specialNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}special_notes'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalOrdersTable createAlias(String alias) {
    return $LocalOrdersTable(attachedDatabase, alias);
  }
}

class LocalOrder extends DataClass implements Insertable<LocalOrder> {
  final String id;
  final String userId;
  final String? vendorId;
  final String? riderId;
  final String status;
  final BigInt subtotal;
  final BigInt deliveryFee;
  final BigInt discount;
  final BigInt totalAmount;
  final String? couponCode;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryStreet;
  final String deliveryCity;
  final String deliveryZip;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? specialNotes;
  final String idempotencyKey;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalOrder({
    required this.id,
    required this.userId,
    this.vendorId,
    this.riderId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.totalAmount,
    this.couponCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryStreet,
    required this.deliveryCity,
    required this.deliveryZip,
    this.deliveryLat,
    this.deliveryLng,
    this.specialNotes,
    required this.idempotencyKey,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || vendorId != null) {
      map['vendor_id'] = Variable<String>(vendorId);
    }
    if (!nullToAbsent || riderId != null) {
      map['rider_id'] = Variable<String>(riderId);
    }
    map['status'] = Variable<String>(status);
    map['subtotal'] = Variable<BigInt>(subtotal);
    map['delivery_fee'] = Variable<BigInt>(deliveryFee);
    map['discount'] = Variable<BigInt>(discount);
    map['total_amount'] = Variable<BigInt>(totalAmount);
    if (!nullToAbsent || couponCode != null) {
      map['coupon_code'] = Variable<String>(couponCode);
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['delivery_street'] = Variable<String>(deliveryStreet);
    map['delivery_city'] = Variable<String>(deliveryCity);
    map['delivery_zip'] = Variable<String>(deliveryZip);
    if (!nullToAbsent || deliveryLat != null) {
      map['delivery_lat'] = Variable<double>(deliveryLat);
    }
    if (!nullToAbsent || deliveryLng != null) {
      map['delivery_lng'] = Variable<double>(deliveryLng);
    }
    if (!nullToAbsent || specialNotes != null) {
      map['special_notes'] = Variable<String>(specialNotes);
    }
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdersCompanion(
      id: Value(id),
      userId: Value(userId),
      vendorId: vendorId == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorId),
      riderId: riderId == null && nullToAbsent
          ? const Value.absent()
          : Value(riderId),
      status: Value(status),
      subtotal: Value(subtotal),
      deliveryFee: Value(deliveryFee),
      discount: Value(discount),
      totalAmount: Value(totalAmount),
      couponCode: couponCode == null && nullToAbsent
          ? const Value.absent()
          : Value(couponCode),
      paymentMethod: Value(paymentMethod),
      paymentStatus: Value(paymentStatus),
      deliveryStreet: Value(deliveryStreet),
      deliveryCity: Value(deliveryCity),
      deliveryZip: Value(deliveryZip),
      deliveryLat: deliveryLat == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryLat),
      deliveryLng: deliveryLng == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveryLng),
      specialNotes: specialNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(specialNotes),
      idempotencyKey: Value(idempotencyKey),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrder(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      vendorId: serializer.fromJson<String?>(json['vendorId']),
      riderId: serializer.fromJson<String?>(json['riderId']),
      status: serializer.fromJson<String>(json['status']),
      subtotal: serializer.fromJson<BigInt>(json['subtotal']),
      deliveryFee: serializer.fromJson<BigInt>(json['deliveryFee']),
      discount: serializer.fromJson<BigInt>(json['discount']),
      totalAmount: serializer.fromJson<BigInt>(json['totalAmount']),
      couponCode: serializer.fromJson<String?>(json['couponCode']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      deliveryStreet: serializer.fromJson<String>(json['deliveryStreet']),
      deliveryCity: serializer.fromJson<String>(json['deliveryCity']),
      deliveryZip: serializer.fromJson<String>(json['deliveryZip']),
      deliveryLat: serializer.fromJson<double?>(json['deliveryLat']),
      deliveryLng: serializer.fromJson<double?>(json['deliveryLng']),
      specialNotes: serializer.fromJson<String?>(json['specialNotes']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'vendorId': serializer.toJson<String?>(vendorId),
      'riderId': serializer.toJson<String?>(riderId),
      'status': serializer.toJson<String>(status),
      'subtotal': serializer.toJson<BigInt>(subtotal),
      'deliveryFee': serializer.toJson<BigInt>(deliveryFee),
      'discount': serializer.toJson<BigInt>(discount),
      'totalAmount': serializer.toJson<BigInt>(totalAmount),
      'couponCode': serializer.toJson<String?>(couponCode),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'deliveryStreet': serializer.toJson<String>(deliveryStreet),
      'deliveryCity': serializer.toJson<String>(deliveryCity),
      'deliveryZip': serializer.toJson<String>(deliveryZip),
      'deliveryLat': serializer.toJson<double?>(deliveryLat),
      'deliveryLng': serializer.toJson<double?>(deliveryLng),
      'specialNotes': serializer.toJson<String?>(specialNotes),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalOrder copyWith({
    String? id,
    String? userId,
    Value<String?> vendorId = const Value.absent(),
    Value<String?> riderId = const Value.absent(),
    String? status,
    BigInt? subtotal,
    BigInt? deliveryFee,
    BigInt? discount,
    BigInt? totalAmount,
    Value<String?> couponCode = const Value.absent(),
    String? paymentMethod,
    String? paymentStatus,
    String? deliveryStreet,
    String? deliveryCity,
    String? deliveryZip,
    Value<double?> deliveryLat = const Value.absent(),
    Value<double?> deliveryLng = const Value.absent(),
    Value<String?> specialNotes = const Value.absent(),
    String? idempotencyKey,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalOrder(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    vendorId: vendorId.present ? vendorId.value : this.vendorId,
    riderId: riderId.present ? riderId.value : this.riderId,
    status: status ?? this.status,
    subtotal: subtotal ?? this.subtotal,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    discount: discount ?? this.discount,
    totalAmount: totalAmount ?? this.totalAmount,
    couponCode: couponCode.present ? couponCode.value : this.couponCode,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    deliveryStreet: deliveryStreet ?? this.deliveryStreet,
    deliveryCity: deliveryCity ?? this.deliveryCity,
    deliveryZip: deliveryZip ?? this.deliveryZip,
    deliveryLat: deliveryLat.present ? deliveryLat.value : this.deliveryLat,
    deliveryLng: deliveryLng.present ? deliveryLng.value : this.deliveryLng,
    specialNotes: specialNotes.present ? specialNotes.value : this.specialNotes,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalOrder copyWithCompanion(LocalOrdersCompanion data) {
    return LocalOrder(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      riderId: data.riderId.present ? data.riderId.value : this.riderId,
      status: data.status.present ? data.status.value : this.status,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      deliveryFee: data.deliveryFee.present
          ? data.deliveryFee.value
          : this.deliveryFee,
      discount: data.discount.present ? data.discount.value : this.discount,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      couponCode: data.couponCode.present
          ? data.couponCode.value
          : this.couponCode,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      deliveryStreet: data.deliveryStreet.present
          ? data.deliveryStreet.value
          : this.deliveryStreet,
      deliveryCity: data.deliveryCity.present
          ? data.deliveryCity.value
          : this.deliveryCity,
      deliveryZip: data.deliveryZip.present
          ? data.deliveryZip.value
          : this.deliveryZip,
      deliveryLat: data.deliveryLat.present
          ? data.deliveryLat.value
          : this.deliveryLat,
      deliveryLng: data.deliveryLng.present
          ? data.deliveryLng.value
          : this.deliveryLng,
      specialNotes: data.specialNotes.present
          ? data.specialNotes.value
          : this.specialNotes,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrder(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vendorId: $vendorId, ')
          ..write('riderId: $riderId, ')
          ..write('status: $status, ')
          ..write('subtotal: $subtotal, ')
          ..write('deliveryFee: $deliveryFee, ')
          ..write('discount: $discount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('couponCode: $couponCode, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('deliveryStreet: $deliveryStreet, ')
          ..write('deliveryCity: $deliveryCity, ')
          ..write('deliveryZip: $deliveryZip, ')
          ..write('deliveryLat: $deliveryLat, ')
          ..write('deliveryLng: $deliveryLng, ')
          ..write('specialNotes: $specialNotes, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    vendorId,
    riderId,
    status,
    subtotal,
    deliveryFee,
    discount,
    totalAmount,
    couponCode,
    paymentMethod,
    paymentStatus,
    deliveryStreet,
    deliveryCity,
    deliveryZip,
    deliveryLat,
    deliveryLng,
    specialNotes,
    idempotencyKey,
    syncStatus,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrder &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.vendorId == this.vendorId &&
          other.riderId == this.riderId &&
          other.status == this.status &&
          other.subtotal == this.subtotal &&
          other.deliveryFee == this.deliveryFee &&
          other.discount == this.discount &&
          other.totalAmount == this.totalAmount &&
          other.couponCode == this.couponCode &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentStatus == this.paymentStatus &&
          other.deliveryStreet == this.deliveryStreet &&
          other.deliveryCity == this.deliveryCity &&
          other.deliveryZip == this.deliveryZip &&
          other.deliveryLat == this.deliveryLat &&
          other.deliveryLng == this.deliveryLng &&
          other.specialNotes == this.specialNotes &&
          other.idempotencyKey == this.idempotencyKey &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalOrdersCompanion extends UpdateCompanion<LocalOrder> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> vendorId;
  final Value<String?> riderId;
  final Value<String> status;
  final Value<BigInt> subtotal;
  final Value<BigInt> deliveryFee;
  final Value<BigInt> discount;
  final Value<BigInt> totalAmount;
  final Value<String?> couponCode;
  final Value<String> paymentMethod;
  final Value<String> paymentStatus;
  final Value<String> deliveryStreet;
  final Value<String> deliveryCity;
  final Value<String> deliveryZip;
  final Value<double?> deliveryLat;
  final Value<double?> deliveryLng;
  final Value<String?> specialNotes;
  final Value<String> idempotencyKey;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalOrdersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.riderId = const Value.absent(),
    this.status = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.deliveryFee = const Value.absent(),
    this.discount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.couponCode = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.deliveryStreet = const Value.absent(),
    this.deliveryCity = const Value.absent(),
    this.deliveryZip = const Value.absent(),
    this.deliveryLat = const Value.absent(),
    this.deliveryLng = const Value.absent(),
    this.specialNotes = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrdersCompanion.insert({
    required String id,
    required String userId,
    this.vendorId = const Value.absent(),
    this.riderId = const Value.absent(),
    this.status = const Value.absent(),
    required BigInt subtotal,
    required BigInt deliveryFee,
    this.discount = const Value.absent(),
    required BigInt totalAmount,
    this.couponCode = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.deliveryStreet = const Value.absent(),
    this.deliveryCity = const Value.absent(),
    this.deliveryZip = const Value.absent(),
    this.deliveryLat = const Value.absent(),
    this.deliveryLng = const Value.absent(),
    this.specialNotes = const Value.absent(),
    required String idempotencyKey,
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       subtotal = Value(subtotal),
       deliveryFee = Value(deliveryFee),
       totalAmount = Value(totalAmount),
       idempotencyKey = Value(idempotencyKey);
  static Insertable<LocalOrder> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? vendorId,
    Expression<String>? riderId,
    Expression<String>? status,
    Expression<BigInt>? subtotal,
    Expression<BigInt>? deliveryFee,
    Expression<BigInt>? discount,
    Expression<BigInt>? totalAmount,
    Expression<String>? couponCode,
    Expression<String>? paymentMethod,
    Expression<String>? paymentStatus,
    Expression<String>? deliveryStreet,
    Expression<String>? deliveryCity,
    Expression<String>? deliveryZip,
    Expression<double>? deliveryLat,
    Expression<double>? deliveryLng,
    Expression<String>? specialNotes,
    Expression<String>? idempotencyKey,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (vendorId != null) 'vendor_id': vendorId,
      if (riderId != null) 'rider_id': riderId,
      if (status != null) 'status': status,
      if (subtotal != null) 'subtotal': subtotal,
      if (deliveryFee != null) 'delivery_fee': deliveryFee,
      if (discount != null) 'discount': discount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (couponCode != null) 'coupon_code': couponCode,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (deliveryStreet != null) 'delivery_street': deliveryStreet,
      if (deliveryCity != null) 'delivery_city': deliveryCity,
      if (deliveryZip != null) 'delivery_zip': deliveryZip,
      if (deliveryLat != null) 'delivery_lat': deliveryLat,
      if (deliveryLng != null) 'delivery_lng': deliveryLng,
      if (specialNotes != null) 'special_notes': specialNotes,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? vendorId,
    Value<String?>? riderId,
    Value<String>? status,
    Value<BigInt>? subtotal,
    Value<BigInt>? deliveryFee,
    Value<BigInt>? discount,
    Value<BigInt>? totalAmount,
    Value<String?>? couponCode,
    Value<String>? paymentMethod,
    Value<String>? paymentStatus,
    Value<String>? deliveryStreet,
    Value<String>? deliveryCity,
    Value<String>? deliveryZip,
    Value<double?>? deliveryLat,
    Value<double?>? deliveryLng,
    Value<String?>? specialNotes,
    Value<String>? idempotencyKey,
    Value<String>? syncStatus,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalOrdersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorId: vendorId ?? this.vendorId,
      riderId: riderId ?? this.riderId,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      couponCode: couponCode ?? this.couponCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryStreet: deliveryStreet ?? this.deliveryStreet,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryZip: deliveryZip ?? this.deliveryZip,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      specialNotes: specialNotes ?? this.specialNotes,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (riderId.present) {
      map['rider_id'] = Variable<String>(riderId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<BigInt>(subtotal.value);
    }
    if (deliveryFee.present) {
      map['delivery_fee'] = Variable<BigInt>(deliveryFee.value);
    }
    if (discount.present) {
      map['discount'] = Variable<BigInt>(discount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<BigInt>(totalAmount.value);
    }
    if (couponCode.present) {
      map['coupon_code'] = Variable<String>(couponCode.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (deliveryStreet.present) {
      map['delivery_street'] = Variable<String>(deliveryStreet.value);
    }
    if (deliveryCity.present) {
      map['delivery_city'] = Variable<String>(deliveryCity.value);
    }
    if (deliveryZip.present) {
      map['delivery_zip'] = Variable<String>(deliveryZip.value);
    }
    if (deliveryLat.present) {
      map['delivery_lat'] = Variable<double>(deliveryLat.value);
    }
    if (deliveryLng.present) {
      map['delivery_lng'] = Variable<double>(deliveryLng.value);
    }
    if (specialNotes.present) {
      map['special_notes'] = Variable<String>(specialNotes.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrdersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('vendorId: $vendorId, ')
          ..write('riderId: $riderId, ')
          ..write('status: $status, ')
          ..write('subtotal: $subtotal, ')
          ..write('deliveryFee: $deliveryFee, ')
          ..write('discount: $discount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('couponCode: $couponCode, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('deliveryStreet: $deliveryStreet, ')
          ..write('deliveryCity: $deliveryCity, ')
          ..write('deliveryZip: $deliveryZip, ')
          ..write('deliveryLat: $deliveryLat, ')
          ..write('deliveryLng: $deliveryLng, ')
          ..write('specialNotes: $specialNotes, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    action,
    payload,
    idempotencyKey,
    attemptCount,
    lastError,
    status,
    nextRetryAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String payload;
  final String idempotencyKey;
  final int attemptCount;
  final String? lastError;
  final String status;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncQueueData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payload,
    required this.idempotencyKey,
    required this.attemptCount,
    this.lastError,
    required this.status,
    this.nextRetryAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(payload),
      idempotencyKey: Value(idempotencyKey),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: serializer.fromJson<String>(json['status']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(status),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    String? payload,
    String? idempotencyKey,
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    String? status,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncQueueData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payload: payload ?? this.payload,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    status: status ?? this.status,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    action,
    payload,
    idempotencyKey,
    attemptCount,
    lastError,
    status,
    nextRetryAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.idempotencyKey == this.idempotencyKey &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.status == this.status &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payload;
  final Value<String> idempotencyKey;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<String> status;
  final Value<DateTime?> nextRetryAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
    required String idempotencyKey,
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       payload = Value(payload),
       idempotencyKey = Value(idempotencyKey);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<String>? idempotencyKey,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<String>? status,
    Expression<DateTime>? nextRetryAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? payload,
    Value<String>? idempotencyKey,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<String>? status,
    Value<DateTime?>? nextRetryAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalItemsTable localItems = $LocalItemsTable(this);
  late final $LocalCartItemsTable localCartItems = $LocalCartItemsTable(this);
  late final $LocalOrdersTable localOrders = $LocalOrdersTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localItems,
    localCartItems,
    localOrders,
    syncQueue,
  ];
}

typedef $$LocalItemsTableCreateCompanionBuilder =
    LocalItemsCompanion Function({
      required String id,
      Value<String?> vendorId,
      required String name,
      Value<String?> description,
      required BigInt price,
      Value<BigInt?> originalPrice,
      required String category,
      Value<String?> imageUrl,
      Value<bool> isAvailable,
      Value<int> prepTime,
      Value<double> rating,
      Value<int> reviewsCount,
      Value<DateTime> syncedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalItemsTableUpdateCompanionBuilder =
    LocalItemsCompanion Function({
      Value<String> id,
      Value<String?> vendorId,
      Value<String> name,
      Value<String?> description,
      Value<BigInt> price,
      Value<BigInt?> originalPrice,
      Value<String> category,
      Value<String?> imageUrl,
      Value<bool> isAvailable,
      Value<int> prepTime,
      Value<double> rating,
      Value<int> reviewsCount,
      Value<DateTime> syncedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalItemsTable> {
  $$LocalItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepTime => $composableBuilder(
    column: $table.prepTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewsCount => $composableBuilder(
    column: $table.reviewsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalItemsTable> {
  $$LocalItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepTime => $composableBuilder(
    column: $table.prepTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewsCount => $composableBuilder(
    column: $table.reviewsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalItemsTable> {
  $$LocalItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<BigInt> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prepTime =>
      $composableBuilder(column: $table.prepTime, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get reviewsCount => $composableBuilder(
    column: $table.reviewsCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalItemsTable,
          LocalItem,
          $$LocalItemsTableFilterComposer,
          $$LocalItemsTableOrderingComposer,
          $$LocalItemsTableAnnotationComposer,
          $$LocalItemsTableCreateCompanionBuilder,
          $$LocalItemsTableUpdateCompanionBuilder,
          (
            LocalItem,
            BaseReferences<_$AppDatabase, $LocalItemsTable, LocalItem>,
          ),
          LocalItem,
          PrefetchHooks Function()
        > {
  $$LocalItemsTableTableManager(_$AppDatabase db, $LocalItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> vendorId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<BigInt> price = const Value.absent(),
                Value<BigInt?> originalPrice = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<int> prepTime = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> reviewsCount = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalItemsCompanion(
                id: id,
                vendorId: vendorId,
                name: name,
                description: description,
                price: price,
                originalPrice: originalPrice,
                category: category,
                imageUrl: imageUrl,
                isAvailable: isAvailable,
                prepTime: prepTime,
                rating: rating,
                reviewsCount: reviewsCount,
                syncedAt: syncedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> vendorId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required BigInt price,
                Value<BigInt?> originalPrice = const Value.absent(),
                required String category,
                Value<String?> imageUrl = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<int> prepTime = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> reviewsCount = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalItemsCompanion.insert(
                id: id,
                vendorId: vendorId,
                name: name,
                description: description,
                price: price,
                originalPrice: originalPrice,
                category: category,
                imageUrl: imageUrl,
                isAvailable: isAvailable,
                prepTime: prepTime,
                rating: rating,
                reviewsCount: reviewsCount,
                syncedAt: syncedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalItemsTable,
      LocalItem,
      $$LocalItemsTableFilterComposer,
      $$LocalItemsTableOrderingComposer,
      $$LocalItemsTableAnnotationComposer,
      $$LocalItemsTableCreateCompanionBuilder,
      $$LocalItemsTableUpdateCompanionBuilder,
      (LocalItem, BaseReferences<_$AppDatabase, $LocalItemsTable, LocalItem>),
      LocalItem,
      PrefetchHooks Function()
    >;
typedef $$LocalCartItemsTableCreateCompanionBuilder =
    LocalCartItemsCompanion Function({
      required String id,
      required String itemId,
      required String name,
      required BigInt price,
      Value<int> quantity,
      Value<String?> imageUrl,
      Value<String?> selectedSpice,
      Value<String?> selectedPortion,
      Value<String?> specialNotes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalCartItemsTableUpdateCompanionBuilder =
    LocalCartItemsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> name,
      Value<BigInt> price,
      Value<int> quantity,
      Value<String?> imageUrl,
      Value<String?> selectedSpice,
      Value<String?> selectedPortion,
      Value<String?> specialNotes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalCartItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCartItemsTable> {
  $$LocalCartItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedSpice => $composableBuilder(
    column: $table.selectedSpice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedPortion => $composableBuilder(
    column: $table.selectedPortion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialNotes => $composableBuilder(
    column: $table.specialNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCartItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCartItemsTable> {
  $$LocalCartItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedSpice => $composableBuilder(
    column: $table.selectedSpice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedPortion => $composableBuilder(
    column: $table.selectedPortion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialNotes => $composableBuilder(
    column: $table.specialNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCartItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCartItemsTable> {
  $$LocalCartItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<BigInt> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get selectedSpice => $composableBuilder(
    column: $table.selectedSpice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedPortion => $composableBuilder(
    column: $table.selectedPortion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialNotes => $composableBuilder(
    column: $table.specialNotes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalCartItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCartItemsTable,
          LocalCartItem,
          $$LocalCartItemsTableFilterComposer,
          $$LocalCartItemsTableOrderingComposer,
          $$LocalCartItemsTableAnnotationComposer,
          $$LocalCartItemsTableCreateCompanionBuilder,
          $$LocalCartItemsTableUpdateCompanionBuilder,
          (
            LocalCartItem,
            BaseReferences<_$AppDatabase, $LocalCartItemsTable, LocalCartItem>,
          ),
          LocalCartItem,
          PrefetchHooks Function()
        > {
  $$LocalCartItemsTableTableManager(
    _$AppDatabase db,
    $LocalCartItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCartItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCartItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCartItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<BigInt> price = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> selectedSpice = const Value.absent(),
                Value<String?> selectedPortion = const Value.absent(),
                Value<String?> specialNotes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCartItemsCompanion(
                id: id,
                itemId: itemId,
                name: name,
                price: price,
                quantity: quantity,
                imageUrl: imageUrl,
                selectedSpice: selectedSpice,
                selectedPortion: selectedPortion,
                specialNotes: specialNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String name,
                required BigInt price,
                Value<int> quantity = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> selectedSpice = const Value.absent(),
                Value<String?> selectedPortion = const Value.absent(),
                Value<String?> specialNotes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalCartItemsCompanion.insert(
                id: id,
                itemId: itemId,
                name: name,
                price: price,
                quantity: quantity,
                imageUrl: imageUrl,
                selectedSpice: selectedSpice,
                selectedPortion: selectedPortion,
                specialNotes: specialNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCartItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCartItemsTable,
      LocalCartItem,
      $$LocalCartItemsTableFilterComposer,
      $$LocalCartItemsTableOrderingComposer,
      $$LocalCartItemsTableAnnotationComposer,
      $$LocalCartItemsTableCreateCompanionBuilder,
      $$LocalCartItemsTableUpdateCompanionBuilder,
      (
        LocalCartItem,
        BaseReferences<_$AppDatabase, $LocalCartItemsTable, LocalCartItem>,
      ),
      LocalCartItem,
      PrefetchHooks Function()
    >;
typedef $$LocalOrdersTableCreateCompanionBuilder =
    LocalOrdersCompanion Function({
      required String id,
      required String userId,
      Value<String?> vendorId,
      Value<String?> riderId,
      Value<String> status,
      required BigInt subtotal,
      required BigInt deliveryFee,
      Value<BigInt> discount,
      required BigInt totalAmount,
      Value<String?> couponCode,
      Value<String> paymentMethod,
      Value<String> paymentStatus,
      Value<String> deliveryStreet,
      Value<String> deliveryCity,
      Value<String> deliveryZip,
      Value<double?> deliveryLat,
      Value<double?> deliveryLng,
      Value<String?> specialNotes,
      required String idempotencyKey,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalOrdersTableUpdateCompanionBuilder =
    LocalOrdersCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> vendorId,
      Value<String?> riderId,
      Value<String> status,
      Value<BigInt> subtotal,
      Value<BigInt> deliveryFee,
      Value<BigInt> discount,
      Value<BigInt> totalAmount,
      Value<String?> couponCode,
      Value<String> paymentMethod,
      Value<String> paymentStatus,
      Value<String> deliveryStreet,
      Value<String> deliveryCity,
      Value<String> deliveryZip,
      Value<double?> deliveryLat,
      Value<double?> deliveryLng,
      Value<String?> specialNotes,
      Value<String> idempotencyKey,
      Value<String> syncStatus,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riderId => $composableBuilder(
    column: $table.riderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get deliveryFee => $composableBuilder(
    column: $table.deliveryFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get couponCode => $composableBuilder(
    column: $table.couponCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryStreet => $composableBuilder(
    column: $table.deliveryStreet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryCity => $composableBuilder(
    column: $table.deliveryCity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryZip => $composableBuilder(
    column: $table.deliveryZip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deliveryLat => $composableBuilder(
    column: $table.deliveryLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deliveryLng => $composableBuilder(
    column: $table.deliveryLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialNotes => $composableBuilder(
    column: $table.specialNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riderId => $composableBuilder(
    column: $table.riderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get deliveryFee => $composableBuilder(
    column: $table.deliveryFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get couponCode => $composableBuilder(
    column: $table.couponCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryStreet => $composableBuilder(
    column: $table.deliveryStreet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryCity => $composableBuilder(
    column: $table.deliveryCity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryZip => $composableBuilder(
    column: $table.deliveryZip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deliveryLat => $composableBuilder(
    column: $table.deliveryLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deliveryLng => $composableBuilder(
    column: $table.deliveryLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialNotes => $composableBuilder(
    column: $table.specialNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<String> get riderId =>
      $composableBuilder(column: $table.riderId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<BigInt> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<BigInt> get deliveryFee => $composableBuilder(
    column: $table.deliveryFee,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<BigInt> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get couponCode => $composableBuilder(
    column: $table.couponCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryStreet => $composableBuilder(
    column: $table.deliveryStreet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryCity => $composableBuilder(
    column: $table.deliveryCity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryZip => $composableBuilder(
    column: $table.deliveryZip,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deliveryLat => $composableBuilder(
    column: $table.deliveryLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deliveryLng => $composableBuilder(
    column: $table.deliveryLng,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialNotes => $composableBuilder(
    column: $table.specialNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalOrdersTable,
          LocalOrder,
          $$LocalOrdersTableFilterComposer,
          $$LocalOrdersTableOrderingComposer,
          $$LocalOrdersTableAnnotationComposer,
          $$LocalOrdersTableCreateCompanionBuilder,
          $$LocalOrdersTableUpdateCompanionBuilder,
          (
            LocalOrder,
            BaseReferences<_$AppDatabase, $LocalOrdersTable, LocalOrder>,
          ),
          LocalOrder,
          PrefetchHooks Function()
        > {
  $$LocalOrdersTableTableManager(_$AppDatabase db, $LocalOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> vendorId = const Value.absent(),
                Value<String?> riderId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<BigInt> subtotal = const Value.absent(),
                Value<BigInt> deliveryFee = const Value.absent(),
                Value<BigInt> discount = const Value.absent(),
                Value<BigInt> totalAmount = const Value.absent(),
                Value<String?> couponCode = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> deliveryStreet = const Value.absent(),
                Value<String> deliveryCity = const Value.absent(),
                Value<String> deliveryZip = const Value.absent(),
                Value<double?> deliveryLat = const Value.absent(),
                Value<double?> deliveryLng = const Value.absent(),
                Value<String?> specialNotes = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion(
                id: id,
                userId: userId,
                vendorId: vendorId,
                riderId: riderId,
                status: status,
                subtotal: subtotal,
                deliveryFee: deliveryFee,
                discount: discount,
                totalAmount: totalAmount,
                couponCode: couponCode,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                deliveryStreet: deliveryStreet,
                deliveryCity: deliveryCity,
                deliveryZip: deliveryZip,
                deliveryLat: deliveryLat,
                deliveryLng: deliveryLng,
                specialNotes: specialNotes,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> vendorId = const Value.absent(),
                Value<String?> riderId = const Value.absent(),
                Value<String> status = const Value.absent(),
                required BigInt subtotal,
                required BigInt deliveryFee,
                Value<BigInt> discount = const Value.absent(),
                required BigInt totalAmount,
                Value<String?> couponCode = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String> deliveryStreet = const Value.absent(),
                Value<String> deliveryCity = const Value.absent(),
                Value<String> deliveryZip = const Value.absent(),
                Value<double?> deliveryLat = const Value.absent(),
                Value<double?> deliveryLng = const Value.absent(),
                Value<String?> specialNotes = const Value.absent(),
                required String idempotencyKey,
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion.insert(
                id: id,
                userId: userId,
                vendorId: vendorId,
                riderId: riderId,
                status: status,
                subtotal: subtotal,
                deliveryFee: deliveryFee,
                discount: discount,
                totalAmount: totalAmount,
                couponCode: couponCode,
                paymentMethod: paymentMethod,
                paymentStatus: paymentStatus,
                deliveryStreet: deliveryStreet,
                deliveryCity: deliveryCity,
                deliveryZip: deliveryZip,
                deliveryLat: deliveryLat,
                deliveryLng: deliveryLng,
                specialNotes: specialNotes,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalOrdersTable,
      LocalOrder,
      $$LocalOrdersTableFilterComposer,
      $$LocalOrdersTableOrderingComposer,
      $$LocalOrdersTableAnnotationComposer,
      $$LocalOrdersTableCreateCompanionBuilder,
      $$LocalOrdersTableUpdateCompanionBuilder,
      (
        LocalOrder,
        BaseReferences<_$AppDatabase, $LocalOrdersTable, LocalOrder>,
      ),
      LocalOrder,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String action,
      required String payload,
      required String idempotencyKey,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<String> status,
      Value<DateTime?> nextRetryAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> action,
      Value<String> payload,
      Value<String> idempotencyKey,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<String> status,
      Value<DateTime?> nextRetryAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payload: payload,
                idempotencyKey: idempotencyKey,
                attemptCount: attemptCount,
                lastError: lastError,
                status: status,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String action,
                required String payload,
                required String idempotencyKey,
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payload: payload,
                idempotencyKey: idempotencyKey,
                attemptCount: attemptCount,
                lastError: lastError,
                status: status,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalItemsTableTableManager get localItems =>
      $$LocalItemsTableTableManager(_db, _db.localItems);
  $$LocalCartItemsTableTableManager get localCartItems =>
      $$LocalCartItemsTableTableManager(_db, _db.localCartItems);
  $$LocalOrdersTableTableManager get localOrders =>
      $$LocalOrdersTableTableManager(_db, _db.localOrders);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
