// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerAddressMeta = const VerificationMeta(
    'customerAddress',
  );
  @override
  late final GeneratedColumn<String> customerAddress = GeneratedColumn<String>(
    'customer_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerLatMeta = const VerificationMeta(
    'customerLat',
  );
  @override
  late final GeneratedColumn<double> customerLat = GeneratedColumn<double>(
    'customer_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customerLngMeta = const VerificationMeta(
    'customerLng',
  );
  @override
  late final GeneratedColumn<double> customerLng = GeneratedColumn<double>(
    'customer_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restaurantLatMeta = const VerificationMeta(
    'restaurantLat',
  );
  @override
  late final GeneratedColumn<double> restaurantLat = GeneratedColumn<double>(
    'restaurant_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restaurantLngMeta = const VerificationMeta(
    'restaurantLng',
  );
  @override
  late final GeneratedColumn<double> restaurantLng = GeneratedColumn<double>(
    'restaurant_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
    status,
    riderId,
    customerName,
    customerPhone,
    customerAddress,
    customerLat,
    customerLng,
    restaurantLat,
    restaurantLng,
    itemsJson,
    totalAmount,
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('rider_id')) {
      context.handle(
        _riderIdMeta,
        riderId.isAcceptableOrUnknown(data['rider_id']!, _riderIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('customer_address')) {
      context.handle(
        _customerAddressMeta,
        customerAddress.isAcceptableOrUnknown(
          data['customer_address']!,
          _customerAddressMeta,
        ),
      );
    }
    if (data.containsKey('customer_lat')) {
      context.handle(
        _customerLatMeta,
        customerLat.isAcceptableOrUnknown(
          data['customer_lat']!,
          _customerLatMeta,
        ),
      );
    }
    if (data.containsKey('customer_lng')) {
      context.handle(
        _customerLngMeta,
        customerLng.isAcceptableOrUnknown(
          data['customer_lng']!,
          _customerLngMeta,
        ),
      );
    }
    if (data.containsKey('restaurant_lat')) {
      context.handle(
        _restaurantLatMeta,
        restaurantLat.isAcceptableOrUnknown(
          data['restaurant_lat']!,
          _restaurantLatMeta,
        ),
      );
    }
    if (data.containsKey('restaurant_lng')) {
      context.handle(
        _restaurantLngMeta,
        restaurantLng.isAcceptableOrUnknown(
          data['restaurant_lng']!,
          _restaurantLngMeta,
        ),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
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
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      riderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rider_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      ),
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      ),
      customerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_address'],
      ),
      customerLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}customer_lat'],
      ),
      customerLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}customer_lng'],
      ),
      restaurantLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}restaurant_lat'],
      ),
      restaurantLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}restaurant_lng'],
      ),
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
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
  final String status;
  final String? riderId;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final double? customerLat;
  final double? customerLng;
  final double? restaurantLat;
  final double? restaurantLng;
  final String itemsJson;
  final double? totalAmount;
  final DateTime? createdAt;
  final DateTime updatedAt;
  const LocalOrder({
    required this.id,
    required this.status,
    this.riderId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerLat,
    this.customerLng,
    this.restaurantLat,
    this.restaurantLng,
    required this.itemsJson,
    this.totalAmount,
    this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || riderId != null) {
      map['rider_id'] = Variable<String>(riderId);
    }
    if (!nullToAbsent || customerName != null) {
      map['customer_name'] = Variable<String>(customerName);
    }
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    if (!nullToAbsent || customerAddress != null) {
      map['customer_address'] = Variable<String>(customerAddress);
    }
    if (!nullToAbsent || customerLat != null) {
      map['customer_lat'] = Variable<double>(customerLat);
    }
    if (!nullToAbsent || customerLng != null) {
      map['customer_lng'] = Variable<double>(customerLng);
    }
    if (!nullToAbsent || restaurantLat != null) {
      map['restaurant_lat'] = Variable<double>(restaurantLat);
    }
    if (!nullToAbsent || restaurantLng != null) {
      map['restaurant_lng'] = Variable<double>(restaurantLng);
    }
    map['items_json'] = Variable<String>(itemsJson);
    if (!nullToAbsent || totalAmount != null) {
      map['total_amount'] = Variable<double>(totalAmount);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdersCompanion(
      id: Value(id),
      status: Value(status),
      riderId: riderId == null && nullToAbsent
          ? const Value.absent()
          : Value(riderId),
      customerName: customerName == null && nullToAbsent
          ? const Value.absent()
          : Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      customerAddress: customerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(customerAddress),
      customerLat: customerLat == null && nullToAbsent
          ? const Value.absent()
          : Value(customerLat),
      customerLng: customerLng == null && nullToAbsent
          ? const Value.absent()
          : Value(customerLng),
      restaurantLat: restaurantLat == null && nullToAbsent
          ? const Value.absent()
          : Value(restaurantLat),
      restaurantLng: restaurantLng == null && nullToAbsent
          ? const Value.absent()
          : Value(restaurantLng),
      itemsJson: Value(itemsJson),
      totalAmount: totalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAmount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
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
      status: serializer.fromJson<String>(json['status']),
      riderId: serializer.fromJson<String?>(json['riderId']),
      customerName: serializer.fromJson<String?>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      customerAddress: serializer.fromJson<String?>(json['customerAddress']),
      customerLat: serializer.fromJson<double?>(json['customerLat']),
      customerLng: serializer.fromJson<double?>(json['customerLng']),
      restaurantLat: serializer.fromJson<double?>(json['restaurantLat']),
      restaurantLng: serializer.fromJson<double?>(json['restaurantLng']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      totalAmount: serializer.fromJson<double?>(json['totalAmount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'riderId': serializer.toJson<String?>(riderId),
      'customerName': serializer.toJson<String?>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'customerAddress': serializer.toJson<String?>(customerAddress),
      'customerLat': serializer.toJson<double?>(customerLat),
      'customerLng': serializer.toJson<double?>(customerLng),
      'restaurantLat': serializer.toJson<double?>(restaurantLat),
      'restaurantLng': serializer.toJson<double?>(restaurantLng),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'totalAmount': serializer.toJson<double?>(totalAmount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalOrder copyWith({
    String? id,
    String? status,
    Value<String?> riderId = const Value.absent(),
    Value<String?> customerName = const Value.absent(),
    Value<String?> customerPhone = const Value.absent(),
    Value<String?> customerAddress = const Value.absent(),
    Value<double?> customerLat = const Value.absent(),
    Value<double?> customerLng = const Value.absent(),
    Value<double?> restaurantLat = const Value.absent(),
    Value<double?> restaurantLng = const Value.absent(),
    String? itemsJson,
    Value<double?> totalAmount = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalOrder(
    id: id ?? this.id,
    status: status ?? this.status,
    riderId: riderId.present ? riderId.value : this.riderId,
    customerName: customerName.present ? customerName.value : this.customerName,
    customerPhone: customerPhone.present
        ? customerPhone.value
        : this.customerPhone,
    customerAddress: customerAddress.present
        ? customerAddress.value
        : this.customerAddress,
    customerLat: customerLat.present ? customerLat.value : this.customerLat,
    customerLng: customerLng.present ? customerLng.value : this.customerLng,
    restaurantLat: restaurantLat.present
        ? restaurantLat.value
        : this.restaurantLat,
    restaurantLng: restaurantLng.present
        ? restaurantLng.value
        : this.restaurantLng,
    itemsJson: itemsJson ?? this.itemsJson,
    totalAmount: totalAmount.present ? totalAmount.value : this.totalAmount,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalOrder copyWithCompanion(LocalOrdersCompanion data) {
    return LocalOrder(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      riderId: data.riderId.present ? data.riderId.value : this.riderId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      customerAddress: data.customerAddress.present
          ? data.customerAddress.value
          : this.customerAddress,
      customerLat: data.customerLat.present
          ? data.customerLat.value
          : this.customerLat,
      customerLng: data.customerLng.present
          ? data.customerLng.value
          : this.customerLng,
      restaurantLat: data.restaurantLat.present
          ? data.restaurantLat.value
          : this.restaurantLat,
      restaurantLng: data.restaurantLng.present
          ? data.restaurantLng.value
          : this.restaurantLng,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrder(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('riderId: $riderId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('customerLat: $customerLat, ')
          ..write('customerLng: $customerLng, ')
          ..write('restaurantLat: $restaurantLat, ')
          ..write('restaurantLng: $restaurantLng, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    riderId,
    customerName,
    customerPhone,
    customerAddress,
    customerLat,
    customerLng,
    restaurantLat,
    restaurantLng,
    itemsJson,
    totalAmount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrder &&
          other.id == this.id &&
          other.status == this.status &&
          other.riderId == this.riderId &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.customerAddress == this.customerAddress &&
          other.customerLat == this.customerLat &&
          other.customerLng == this.customerLng &&
          other.restaurantLat == this.restaurantLat &&
          other.restaurantLng == this.restaurantLng &&
          other.itemsJson == this.itemsJson &&
          other.totalAmount == this.totalAmount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalOrdersCompanion extends UpdateCompanion<LocalOrder> {
  final Value<String> id;
  final Value<String> status;
  final Value<String?> riderId;
  final Value<String?> customerName;
  final Value<String?> customerPhone;
  final Value<String?> customerAddress;
  final Value<double?> customerLat;
  final Value<double?> customerLng;
  final Value<double?> restaurantLat;
  final Value<double?> restaurantLng;
  final Value<String> itemsJson;
  final Value<double?> totalAmount;
  final Value<DateTime?> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalOrdersCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.riderId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.customerLat = const Value.absent(),
    this.customerLng = const Value.absent(),
    this.restaurantLat = const Value.absent(),
    this.restaurantLng = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrdersCompanion.insert({
    required String id,
    this.status = const Value.absent(),
    this.riderId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.customerAddress = const Value.absent(),
    this.customerLat = const Value.absent(),
    this.customerLng = const Value.absent(),
    this.restaurantLat = const Value.absent(),
    this.restaurantLng = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<LocalOrder> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? riderId,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<String>? customerAddress,
    Expression<double>? customerLat,
    Expression<double>? customerLng,
    Expression<double>? restaurantLat,
    Expression<double>? restaurantLng,
    Expression<String>? itemsJson,
    Expression<double>? totalAmount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (riderId != null) 'rider_id': riderId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (customerAddress != null) 'customer_address': customerAddress,
      if (customerLat != null) 'customer_lat': customerLat,
      if (customerLng != null) 'customer_lng': customerLng,
      if (restaurantLat != null) 'restaurant_lat': restaurantLat,
      if (restaurantLng != null) 'restaurant_lng': restaurantLng,
      if (itemsJson != null) 'items_json': itemsJson,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String?>? riderId,
    Value<String?>? customerName,
    Value<String?>? customerPhone,
    Value<String?>? customerAddress,
    Value<double?>? customerLat,
    Value<double?>? customerLng,
    Value<double?>? restaurantLat,
    Value<double?>? restaurantLng,
    Value<String>? itemsJson,
    Value<double?>? totalAmount,
    Value<DateTime?>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalOrdersCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      riderId: riderId ?? this.riderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      itemsJson: itemsJson ?? this.itemsJson,
      totalAmount: totalAmount ?? this.totalAmount,
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
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (riderId.present) {
      map['rider_id'] = Variable<String>(riderId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (customerAddress.present) {
      map['customer_address'] = Variable<String>(customerAddress.value);
    }
    if (customerLat.present) {
      map['customer_lat'] = Variable<double>(customerLat.value);
    }
    if (customerLng.present) {
      map['customer_lng'] = Variable<double>(customerLng.value);
    }
    if (restaurantLat.present) {
      map['restaurant_lat'] = Variable<double>(restaurantLat.value);
    }
    if (restaurantLng.present) {
      map['restaurant_lng'] = Variable<double>(restaurantLng.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
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
          ..write('status: $status, ')
          ..write('riderId: $riderId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('customerAddress: $customerAddress, ')
          ..write('customerLat: $customerLat, ')
          ..write('customerLng: $customerLng, ')
          ..write('restaurantLat: $restaurantLat, ')
          ..write('restaurantLng: $restaurantLng, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRiderProfileTable extends LocalRiderProfile
    with TableInfo<$LocalRiderProfileTable, LocalRiderProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRiderProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  List<GeneratedColumn> get $columns => [id, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_rider_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalRiderProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
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
  LocalRiderProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRiderProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalRiderProfileTable createAlias(String alias) {
    return $LocalRiderProfileTable(attachedDatabase, alias);
  }
}

class LocalRiderProfileData extends DataClass
    implements Insertable<LocalRiderProfileData> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  const LocalRiderProfileData({
    required this.id,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalRiderProfileCompanion toCompanion(bool nullToAbsent) {
    return LocalRiderProfileCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalRiderProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRiderProfileData(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalRiderProfileData copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
  }) => LocalRiderProfileData(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalRiderProfileData copyWithCompanion(LocalRiderProfileCompanion data) {
    return LocalRiderProfileData(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRiderProfileData(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRiderProfileData &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class LocalRiderProfileCompanion
    extends UpdateCompanion<LocalRiderProfileData> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalRiderProfileCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRiderProfileCompanion.insert({
    required String id,
    required String payload,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<LocalRiderProfileData> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRiderProfileCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalRiderProfileCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
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
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
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
    return (StringBuffer('LocalRiderProfileCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
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
  late final $LocalOrdersTable localOrders = $LocalOrdersTable(this);
  late final $LocalRiderProfileTable localRiderProfile =
      $LocalRiderProfileTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localOrders,
    localRiderProfile,
    syncQueue,
  ];
}

typedef $$LocalOrdersTableCreateCompanionBuilder =
    LocalOrdersCompanion Function({
      required String id,
      Value<String> status,
      Value<String?> riderId,
      Value<String?> customerName,
      Value<String?> customerPhone,
      Value<String?> customerAddress,
      Value<double?> customerLat,
      Value<double?> customerLng,
      Value<double?> restaurantLat,
      Value<double?> restaurantLng,
      Value<String> itemsJson,
      Value<double?> totalAmount,
      Value<DateTime?> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalOrdersTableUpdateCompanionBuilder =
    LocalOrdersCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<String?> riderId,
      Value<String?> customerName,
      Value<String?> customerPhone,
      Value<String?> customerAddress,
      Value<double?> customerLat,
      Value<double?> customerLng,
      Value<double?> restaurantLat,
      Value<double?> restaurantLng,
      Value<String> itemsJson,
      Value<double?> totalAmount,
      Value<DateTime?> createdAt,
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riderId => $composableBuilder(
    column: $table.riderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get customerLat => $composableBuilder(
    column: $table.customerLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get customerLng => $composableBuilder(
    column: $table.customerLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get restaurantLat => $composableBuilder(
    column: $table.restaurantLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get restaurantLng => $composableBuilder(
    column: $table.restaurantLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riderId => $composableBuilder(
    column: $table.riderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get customerLat => $composableBuilder(
    column: $table.customerLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get customerLng => $composableBuilder(
    column: $table.customerLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get restaurantLat => $composableBuilder(
    column: $table.restaurantLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get restaurantLng => $composableBuilder(
    column: $table.restaurantLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
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

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get riderId =>
      $composableBuilder(column: $table.riderId, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerAddress => $composableBuilder(
    column: $table.customerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<double> get customerLat => $composableBuilder(
    column: $table.customerLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get customerLng => $composableBuilder(
    column: $table.customerLng,
    builder: (column) => column,
  );

  GeneratedColumn<double> get restaurantLat => $composableBuilder(
    column: $table.restaurantLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get restaurantLng => $composableBuilder(
    column: $table.restaurantLng,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
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
                Value<String> status = const Value.absent(),
                Value<String?> riderId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<double?> customerLat = const Value.absent(),
                Value<double?> customerLng = const Value.absent(),
                Value<double?> restaurantLat = const Value.absent(),
                Value<double?> restaurantLng = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion(
                id: id,
                status: status,
                riderId: riderId,
                customerName: customerName,
                customerPhone: customerPhone,
                customerAddress: customerAddress,
                customerLat: customerLat,
                customerLng: customerLng,
                restaurantLat: restaurantLat,
                restaurantLng: restaurantLng,
                itemsJson: itemsJson,
                totalAmount: totalAmount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> status = const Value.absent(),
                Value<String?> riderId = const Value.absent(),
                Value<String?> customerName = const Value.absent(),
                Value<String?> customerPhone = const Value.absent(),
                Value<String?> customerAddress = const Value.absent(),
                Value<double?> customerLat = const Value.absent(),
                Value<double?> customerLng = const Value.absent(),
                Value<double?> restaurantLat = const Value.absent(),
                Value<double?> restaurantLng = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion.insert(
                id: id,
                status: status,
                riderId: riderId,
                customerName: customerName,
                customerPhone: customerPhone,
                customerAddress: customerAddress,
                customerLat: customerLat,
                customerLng: customerLng,
                restaurantLat: restaurantLat,
                restaurantLng: restaurantLng,
                itemsJson: itemsJson,
                totalAmount: totalAmount,
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
typedef $$LocalRiderProfileTableCreateCompanionBuilder =
    LocalRiderProfileCompanion Function({
      required String id,
      required String payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalRiderProfileTableUpdateCompanionBuilder =
    LocalRiderProfileCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalRiderProfileTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRiderProfileTable> {
  $$LocalRiderProfileTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRiderProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRiderProfileTable> {
  $$LocalRiderProfileTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRiderProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRiderProfileTable> {
  $$LocalRiderProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalRiderProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalRiderProfileTable,
          LocalRiderProfileData,
          $$LocalRiderProfileTableFilterComposer,
          $$LocalRiderProfileTableOrderingComposer,
          $$LocalRiderProfileTableAnnotationComposer,
          $$LocalRiderProfileTableCreateCompanionBuilder,
          $$LocalRiderProfileTableUpdateCompanionBuilder,
          (
            LocalRiderProfileData,
            BaseReferences<
              _$AppDatabase,
              $LocalRiderProfileTable,
              LocalRiderProfileData
            >,
          ),
          LocalRiderProfileData,
          PrefetchHooks Function()
        > {
  $$LocalRiderProfileTableTableManager(
    _$AppDatabase db,
    $LocalRiderProfileTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRiderProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRiderProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRiderProfileTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRiderProfileCompanion(
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRiderProfileCompanion.insert(
                id: id,
                payload: payload,
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

typedef $$LocalRiderProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalRiderProfileTable,
      LocalRiderProfileData,
      $$LocalRiderProfileTableFilterComposer,
      $$LocalRiderProfileTableOrderingComposer,
      $$LocalRiderProfileTableAnnotationComposer,
      $$LocalRiderProfileTableCreateCompanionBuilder,
      $$LocalRiderProfileTableUpdateCompanionBuilder,
      (
        LocalRiderProfileData,
        BaseReferences<
          _$AppDatabase,
          $LocalRiderProfileTable,
          LocalRiderProfileData
        >,
      ),
      LocalRiderProfileData,
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
  $$LocalOrdersTableTableManager get localOrders =>
      $$LocalOrdersTableTableManager(_db, _db.localOrders);
  $$LocalRiderProfileTableTableManager get localRiderProfile =>
      $$LocalRiderProfileTableTableManager(_db, _db.localRiderProfile);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
