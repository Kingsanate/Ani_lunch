// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalVendorOrdersTable extends LocalVendorOrders
    with TableInfo<$LocalVendorOrdersTable, LocalVendorOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalVendorOrdersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _orderTimeMeta = const VerificationMeta(
    'orderTime',
  );
  @override
  late final GeneratedColumn<DateTime> orderTime = GeneratedColumn<DateTime>(
    'order_time',
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
    vendorId,
    payload,
    orderTime,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_vendor_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalVendorOrder> instance, {
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
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('order_time')) {
      context.handle(
        _orderTimeMeta,
        orderTime.isAcceptableOrUnknown(data['order_time']!, _orderTimeMeta),
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
  LocalVendorOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalVendorOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      vendorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      orderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}order_time'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalVendorOrdersTable createAlias(String alias) {
    return $LocalVendorOrdersTable(attachedDatabase, alias);
  }
}

class LocalVendorOrder extends DataClass
    implements Insertable<LocalVendorOrder> {
  final String id;
  final String status;
  final String? vendorId;
  final String payload;
  final DateTime? orderTime;
  final DateTime updatedAt;
  const LocalVendorOrder({
    required this.id,
    required this.status,
    this.vendorId,
    required this.payload,
    this.orderTime,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || vendorId != null) {
      map['vendor_id'] = Variable<String>(vendorId);
    }
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || orderTime != null) {
      map['order_time'] = Variable<DateTime>(orderTime);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalVendorOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalVendorOrdersCompanion(
      id: Value(id),
      status: Value(status),
      vendorId: vendorId == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorId),
      payload: Value(payload),
      orderTime: orderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(orderTime),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalVendorOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalVendorOrder(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      vendorId: serializer.fromJson<String?>(json['vendorId']),
      payload: serializer.fromJson<String>(json['payload']),
      orderTime: serializer.fromJson<DateTime?>(json['orderTime']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'vendorId': serializer.toJson<String?>(vendorId),
      'payload': serializer.toJson<String>(payload),
      'orderTime': serializer.toJson<DateTime?>(orderTime),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalVendorOrder copyWith({
    String? id,
    String? status,
    Value<String?> vendorId = const Value.absent(),
    String? payload,
    Value<DateTime?> orderTime = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalVendorOrder(
    id: id ?? this.id,
    status: status ?? this.status,
    vendorId: vendorId.present ? vendorId.value : this.vendorId,
    payload: payload ?? this.payload,
    orderTime: orderTime.present ? orderTime.value : this.orderTime,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalVendorOrder copyWithCompanion(LocalVendorOrdersCompanion data) {
    return LocalVendorOrder(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      payload: data.payload.present ? data.payload.value : this.payload,
      orderTime: data.orderTime.present ? data.orderTime.value : this.orderTime,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalVendorOrder(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('vendorId: $vendorId, ')
          ..write('payload: $payload, ')
          ..write('orderTime: $orderTime, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, status, vendorId, payload, orderTime, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalVendorOrder &&
          other.id == this.id &&
          other.status == this.status &&
          other.vendorId == this.vendorId &&
          other.payload == this.payload &&
          other.orderTime == this.orderTime &&
          other.updatedAt == this.updatedAt);
}

class LocalVendorOrdersCompanion extends UpdateCompanion<LocalVendorOrder> {
  final Value<String> id;
  final Value<String> status;
  final Value<String?> vendorId;
  final Value<String> payload;
  final Value<DateTime?> orderTime;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalVendorOrdersCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.payload = const Value.absent(),
    this.orderTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalVendorOrdersCompanion.insert({
    required String id,
    this.status = const Value.absent(),
    this.vendorId = const Value.absent(),
    required String payload,
    this.orderTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<LocalVendorOrder> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? vendorId,
    Expression<String>? payload,
    Expression<DateTime>? orderTime,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (vendorId != null) 'vendor_id': vendorId,
      if (payload != null) 'payload': payload,
      if (orderTime != null) 'order_time': orderTime,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalVendorOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String?>? vendorId,
    Value<String>? payload,
    Value<DateTime?>? orderTime,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalVendorOrdersCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      vendorId: vendorId ?? this.vendorId,
      payload: payload ?? this.payload,
      orderTime: orderTime ?? this.orderTime,
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
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (orderTime.present) {
      map['order_time'] = Variable<DateTime>(orderTime.value);
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
    return (StringBuffer('LocalVendorOrdersCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('vendorId: $vendorId, ')
          ..write('payload: $payload, ')
          ..write('orderTime: $orderTime, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalVendorProfileTable extends LocalVendorProfile
    with TableInfo<$LocalVendorProfileTable, LocalVendorProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalVendorProfileTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'local_vendor_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalVendorProfileData> instance, {
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
  LocalVendorProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalVendorProfileData(
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
  $LocalVendorProfileTable createAlias(String alias) {
    return $LocalVendorProfileTable(attachedDatabase, alias);
  }
}

class LocalVendorProfileData extends DataClass
    implements Insertable<LocalVendorProfileData> {
  final String id;
  final String payload;
  final DateTime updatedAt;
  const LocalVendorProfileData({
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

  LocalVendorProfileCompanion toCompanion(bool nullToAbsent) {
    return LocalVendorProfileCompanion(
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalVendorProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalVendorProfileData(
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

  LocalVendorProfileData copyWith({
    String? id,
    String? payload,
    DateTime? updatedAt,
  }) => LocalVendorProfileData(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalVendorProfileData copyWithCompanion(LocalVendorProfileCompanion data) {
    return LocalVendorProfileData(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalVendorProfileData(')
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
      (other is LocalVendorProfileData &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class LocalVendorProfileCompanion
    extends UpdateCompanion<LocalVendorProfileData> {
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalVendorProfileCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalVendorProfileCompanion.insert({
    required String id,
    required String payload,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<LocalVendorProfileData> custom({
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

  LocalVendorProfileCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalVendorProfileCompanion(
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
    return (StringBuffer('LocalVendorProfileCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProductTable extends LocalProduct
    with TableInfo<$LocalProductTable, LocalProductData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProductTable(this.attachedDatabase, [this._alias]);
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [
    id,
    vendorId,
    name,
    price,
    payload,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_product';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProductData> instance, {
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
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
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
  LocalProductData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProductData(
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
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
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
  $LocalProductTable createAlias(String alias) {
    return $LocalProductTable(attachedDatabase, alias);
  }
}

class LocalProductData extends DataClass
    implements Insertable<LocalProductData> {
  final String id;
  final String? vendorId;
  final String name;
  final double? price;
  final String payload;
  final DateTime updatedAt;
  const LocalProductData({
    required this.id,
    this.vendorId,
    required this.name,
    this.price,
    required this.payload,
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
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalProductCompanion toCompanion(bool nullToAbsent) {
    return LocalProductCompanion(
      id: Value(id),
      vendorId: vendorId == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorId),
      name: Value(name),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalProductData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProductData(
      id: serializer.fromJson<String>(json['id']),
      vendorId: serializer.fromJson<String?>(json['vendorId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double?>(json['price']),
      payload: serializer.fromJson<String>(json['payload']),
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
      'price': serializer.toJson<double?>(price),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalProductData copyWith({
    String? id,
    Value<String?> vendorId = const Value.absent(),
    String? name,
    Value<double?> price = const Value.absent(),
    String? payload,
    DateTime? updatedAt,
  }) => LocalProductData(
    id: id ?? this.id,
    vendorId: vendorId.present ? vendorId.value : this.vendorId,
    name: name ?? this.name,
    price: price.present ? price.value : this.price,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalProductData copyWithCompanion(LocalProductCompanion data) {
    return LocalProductData(
      id: data.id.present ? data.id.value : this.id,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProductData(')
          ..write('id: $id, ')
          ..write('vendorId: $vendorId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, vendorId, name, price, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProductData &&
          other.id == this.id &&
          other.vendorId == this.vendorId &&
          other.name == this.name &&
          other.price == this.price &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class LocalProductCompanion extends UpdateCompanion<LocalProductData> {
  final Value<String> id;
  final Value<String?> vendorId;
  final Value<String> name;
  final Value<double?> price;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalProductCompanion({
    this.id = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProductCompanion.insert({
    required String id,
    this.vendorId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    required String payload,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<LocalProductData> custom({
    Expression<String>? id,
    Expression<String>? vendorId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vendorId != null) 'vendor_id': vendorId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProductCompanion copyWith({
    Value<String>? id,
    Value<String?>? vendorId,
    Value<String>? name,
    Value<double?>? price,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalProductCompanion(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      price: price ?? this.price,
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
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
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
    return (StringBuffer('LocalProductCompanion(')
          ..write('id: $id, ')
          ..write('vendorId: $vendorId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStatsTable extends LocalStats
    with TableInfo<$LocalStatsTable, LocalStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vendorIdMeta = const VerificationMeta(
    'vendorId',
  );
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
    'vendor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _todaySalesMeta = const VerificationMeta(
    'todaySales',
  );
  @override
  late final GeneratedColumn<double> todaySales = GeneratedColumn<double>(
    'today_sales',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _todayOrdersMeta = const VerificationMeta(
    'todayOrders',
  );
  @override
  late final GeneratedColumn<int> todayOrders = GeneratedColumn<int>(
    'today_orders',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    vendorId,
    todaySales,
    todayOrders,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vendorIdMeta);
    }
    if (data.containsKey('today_sales')) {
      context.handle(
        _todaySalesMeta,
        todaySales.isAcceptableOrUnknown(data['today_sales']!, _todaySalesMeta),
      );
    }
    if (data.containsKey('today_orders')) {
      context.handle(
        _todayOrdersMeta,
        todayOrders.isAcceptableOrUnknown(
          data['today_orders']!,
          _todayOrdersMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {vendorId};
  @override
  LocalStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStat(
      vendorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vendor_id'],
      )!,
      todaySales: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}today_sales'],
      )!,
      todayOrders: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}today_orders'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalStatsTable createAlias(String alias) {
    return $LocalStatsTable(attachedDatabase, alias);
  }
}

class LocalStat extends DataClass implements Insertable<LocalStat> {
  final String vendorId;
  final double todaySales;
  final int todayOrders;
  final DateTime updatedAt;
  const LocalStat({
    required this.vendorId,
    required this.todaySales,
    required this.todayOrders,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vendor_id'] = Variable<String>(vendorId);
    map['today_sales'] = Variable<double>(todaySales);
    map['today_orders'] = Variable<int>(todayOrders);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalStatsCompanion toCompanion(bool nullToAbsent) {
    return LocalStatsCompanion(
      vendorId: Value(vendorId),
      todaySales: Value(todaySales),
      todayOrders: Value(todayOrders),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalStat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStat(
      vendorId: serializer.fromJson<String>(json['vendorId']),
      todaySales: serializer.fromJson<double>(json['todaySales']),
      todayOrders: serializer.fromJson<int>(json['todayOrders']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vendorId': serializer.toJson<String>(vendorId),
      'todaySales': serializer.toJson<double>(todaySales),
      'todayOrders': serializer.toJson<int>(todayOrders),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalStat copyWith({
    String? vendorId,
    double? todaySales,
    int? todayOrders,
    DateTime? updatedAt,
  }) => LocalStat(
    vendorId: vendorId ?? this.vendorId,
    todaySales: todaySales ?? this.todaySales,
    todayOrders: todayOrders ?? this.todayOrders,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalStat copyWithCompanion(LocalStatsCompanion data) {
    return LocalStat(
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      todaySales: data.todaySales.present
          ? data.todaySales.value
          : this.todaySales,
      todayOrders: data.todayOrders.present
          ? data.todayOrders.value
          : this.todayOrders,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStat(')
          ..write('vendorId: $vendorId, ')
          ..write('todaySales: $todaySales, ')
          ..write('todayOrders: $todayOrders, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(vendorId, todaySales, todayOrders, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStat &&
          other.vendorId == this.vendorId &&
          other.todaySales == this.todaySales &&
          other.todayOrders == this.todayOrders &&
          other.updatedAt == this.updatedAt);
}

class LocalStatsCompanion extends UpdateCompanion<LocalStat> {
  final Value<String> vendorId;
  final Value<double> todaySales;
  final Value<int> todayOrders;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalStatsCompanion({
    this.vendorId = const Value.absent(),
    this.todaySales = const Value.absent(),
    this.todayOrders = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStatsCompanion.insert({
    required String vendorId,
    this.todaySales = const Value.absent(),
    this.todayOrders = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : vendorId = Value(vendorId);
  static Insertable<LocalStat> custom({
    Expression<String>? vendorId,
    Expression<double>? todaySales,
    Expression<int>? todayOrders,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vendorId != null) 'vendor_id': vendorId,
      if (todaySales != null) 'today_sales': todaySales,
      if (todayOrders != null) 'today_orders': todayOrders,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStatsCompanion copyWith({
    Value<String>? vendorId,
    Value<double>? todaySales,
    Value<int>? todayOrders,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalStatsCompanion(
      vendorId: vendorId ?? this.vendorId,
      todaySales: todaySales ?? this.todaySales,
      todayOrders: todayOrders ?? this.todayOrders,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (todaySales.present) {
      map['today_sales'] = Variable<double>(todaySales.value);
    }
    if (todayOrders.present) {
      map['today_orders'] = Variable<int>(todayOrders.value);
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
    return (StringBuffer('LocalStatsCompanion(')
          ..write('vendorId: $vendorId, ')
          ..write('todaySales: $todaySales, ')
          ..write('todayOrders: $todayOrders, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalVendorOrdersTable localVendorOrders =
      $LocalVendorOrdersTable(this);
  late final $LocalVendorProfileTable localVendorProfile =
      $LocalVendorProfileTable(this);
  late final $LocalProductTable localProduct = $LocalProductTable(this);
  late final $LocalStatsTable localStats = $LocalStatsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localVendorOrders,
    localVendorProfile,
    localProduct,
    localStats,
  ];
}

typedef $$LocalVendorOrdersTableCreateCompanionBuilder =
    LocalVendorOrdersCompanion Function({
      required String id,
      Value<String> status,
      Value<String?> vendorId,
      required String payload,
      Value<DateTime?> orderTime,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalVendorOrdersTableUpdateCompanionBuilder =
    LocalVendorOrdersCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<String?> vendorId,
      Value<String> payload,
      Value<DateTime?> orderTime,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalVendorOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalVendorOrdersTable> {
  $$LocalVendorOrdersTableFilterComposer({
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

  ColumnFilters<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get orderTime => $composableBuilder(
    column: $table.orderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalVendorOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalVendorOrdersTable> {
  $$LocalVendorOrdersTableOrderingComposer({
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

  ColumnOrderings<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get orderTime => $composableBuilder(
    column: $table.orderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalVendorOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalVendorOrdersTable> {
  $$LocalVendorOrdersTableAnnotationComposer({
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

  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get orderTime =>
      $composableBuilder(column: $table.orderTime, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalVendorOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalVendorOrdersTable,
          LocalVendorOrder,
          $$LocalVendorOrdersTableFilterComposer,
          $$LocalVendorOrdersTableOrderingComposer,
          $$LocalVendorOrdersTableAnnotationComposer,
          $$LocalVendorOrdersTableCreateCompanionBuilder,
          $$LocalVendorOrdersTableUpdateCompanionBuilder,
          (
            LocalVendorOrder,
            BaseReferences<
              _$AppDatabase,
              $LocalVendorOrdersTable,
              LocalVendorOrder
            >,
          ),
          LocalVendorOrder,
          PrefetchHooks Function()
        > {
  $$LocalVendorOrdersTableTableManager(
    _$AppDatabase db,
    $LocalVendorOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalVendorOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalVendorOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalVendorOrdersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> vendorId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime?> orderTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalVendorOrdersCompanion(
                id: id,
                status: status,
                vendorId: vendorId,
                payload: payload,
                orderTime: orderTime,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> status = const Value.absent(),
                Value<String?> vendorId = const Value.absent(),
                required String payload,
                Value<DateTime?> orderTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalVendorOrdersCompanion.insert(
                id: id,
                status: status,
                vendorId: vendorId,
                payload: payload,
                orderTime: orderTime,
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

typedef $$LocalVendorOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalVendorOrdersTable,
      LocalVendorOrder,
      $$LocalVendorOrdersTableFilterComposer,
      $$LocalVendorOrdersTableOrderingComposer,
      $$LocalVendorOrdersTableAnnotationComposer,
      $$LocalVendorOrdersTableCreateCompanionBuilder,
      $$LocalVendorOrdersTableUpdateCompanionBuilder,
      (
        LocalVendorOrder,
        BaseReferences<
          _$AppDatabase,
          $LocalVendorOrdersTable,
          LocalVendorOrder
        >,
      ),
      LocalVendorOrder,
      PrefetchHooks Function()
    >;
typedef $$LocalVendorProfileTableCreateCompanionBuilder =
    LocalVendorProfileCompanion Function({
      required String id,
      required String payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalVendorProfileTableUpdateCompanionBuilder =
    LocalVendorProfileCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalVendorProfileTableFilterComposer
    extends Composer<_$AppDatabase, $LocalVendorProfileTable> {
  $$LocalVendorProfileTableFilterComposer({
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

class $$LocalVendorProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalVendorProfileTable> {
  $$LocalVendorProfileTableOrderingComposer({
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

class $$LocalVendorProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalVendorProfileTable> {
  $$LocalVendorProfileTableAnnotationComposer({
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

class $$LocalVendorProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalVendorProfileTable,
          LocalVendorProfileData,
          $$LocalVendorProfileTableFilterComposer,
          $$LocalVendorProfileTableOrderingComposer,
          $$LocalVendorProfileTableAnnotationComposer,
          $$LocalVendorProfileTableCreateCompanionBuilder,
          $$LocalVendorProfileTableUpdateCompanionBuilder,
          (
            LocalVendorProfileData,
            BaseReferences<
              _$AppDatabase,
              $LocalVendorProfileTable,
              LocalVendorProfileData
            >,
          ),
          LocalVendorProfileData,
          PrefetchHooks Function()
        > {
  $$LocalVendorProfileTableTableManager(
    _$AppDatabase db,
    $LocalVendorProfileTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalVendorProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalVendorProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalVendorProfileTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalVendorProfileCompanion(
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
              }) => LocalVendorProfileCompanion.insert(
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

typedef $$LocalVendorProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalVendorProfileTable,
      LocalVendorProfileData,
      $$LocalVendorProfileTableFilterComposer,
      $$LocalVendorProfileTableOrderingComposer,
      $$LocalVendorProfileTableAnnotationComposer,
      $$LocalVendorProfileTableCreateCompanionBuilder,
      $$LocalVendorProfileTableUpdateCompanionBuilder,
      (
        LocalVendorProfileData,
        BaseReferences<
          _$AppDatabase,
          $LocalVendorProfileTable,
          LocalVendorProfileData
        >,
      ),
      LocalVendorProfileData,
      PrefetchHooks Function()
    >;
typedef $$LocalProductTableCreateCompanionBuilder =
    LocalProductCompanion Function({
      required String id,
      Value<String?> vendorId,
      Value<String> name,
      Value<double?> price,
      required String payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalProductTableUpdateCompanionBuilder =
    LocalProductCompanion Function({
      Value<String> id,
      Value<String?> vendorId,
      Value<String> name,
      Value<double?> price,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalProductTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProductTable> {
  $$LocalProductTableFilterComposer({
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

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
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

class $$LocalProductTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProductTable> {
  $$LocalProductTableOrderingComposer({
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

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
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

class $$LocalProductTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProductTable> {
  $$LocalProductTableAnnotationComposer({
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

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalProductTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProductTable,
          LocalProductData,
          $$LocalProductTableFilterComposer,
          $$LocalProductTableOrderingComposer,
          $$LocalProductTableAnnotationComposer,
          $$LocalProductTableCreateCompanionBuilder,
          $$LocalProductTableUpdateCompanionBuilder,
          (
            LocalProductData,
            BaseReferences<_$AppDatabase, $LocalProductTable, LocalProductData>,
          ),
          LocalProductData,
          PrefetchHooks Function()
        > {
  $$LocalProductTableTableManager(_$AppDatabase db, $LocalProductTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProductTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProductTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProductTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> vendorId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductCompanion(
                id: id,
                vendorId: vendorId,
                name: name,
                price: price,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> vendorId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> price = const Value.absent(),
                required String payload,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProductCompanion.insert(
                id: id,
                vendorId: vendorId,
                name: name,
                price: price,
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

typedef $$LocalProductTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProductTable,
      LocalProductData,
      $$LocalProductTableFilterComposer,
      $$LocalProductTableOrderingComposer,
      $$LocalProductTableAnnotationComposer,
      $$LocalProductTableCreateCompanionBuilder,
      $$LocalProductTableUpdateCompanionBuilder,
      (
        LocalProductData,
        BaseReferences<_$AppDatabase, $LocalProductTable, LocalProductData>,
      ),
      LocalProductData,
      PrefetchHooks Function()
    >;
typedef $$LocalStatsTableCreateCompanionBuilder =
    LocalStatsCompanion Function({
      required String vendorId,
      Value<double> todaySales,
      Value<int> todayOrders,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalStatsTableUpdateCompanionBuilder =
    LocalStatsCompanion Function({
      Value<String> vendorId,
      Value<double> todaySales,
      Value<int> todayOrders,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalStatsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStatsTable> {
  $$LocalStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get todaySales => $composableBuilder(
    column: $table.todaySales,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get todayOrders => $composableBuilder(
    column: $table.todayOrders,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStatsTable> {
  $$LocalStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get todaySales => $composableBuilder(
    column: $table.todaySales,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get todayOrders => $composableBuilder(
    column: $table.todayOrders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStatsTable> {
  $$LocalStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<double> get todaySales => $composableBuilder(
    column: $table.todaySales,
    builder: (column) => column,
  );

  GeneratedColumn<int> get todayOrders => $composableBuilder(
    column: $table.todayOrders,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStatsTable,
          LocalStat,
          $$LocalStatsTableFilterComposer,
          $$LocalStatsTableOrderingComposer,
          $$LocalStatsTableAnnotationComposer,
          $$LocalStatsTableCreateCompanionBuilder,
          $$LocalStatsTableUpdateCompanionBuilder,
          (
            LocalStat,
            BaseReferences<_$AppDatabase, $LocalStatsTable, LocalStat>,
          ),
          LocalStat,
          PrefetchHooks Function()
        > {
  $$LocalStatsTableTableManager(_$AppDatabase db, $LocalStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> vendorId = const Value.absent(),
                Value<double> todaySales = const Value.absent(),
                Value<int> todayOrders = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStatsCompanion(
                vendorId: vendorId,
                todaySales: todaySales,
                todayOrders: todayOrders,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String vendorId,
                Value<double> todaySales = const Value.absent(),
                Value<int> todayOrders = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStatsCompanion.insert(
                vendorId: vendorId,
                todaySales: todaySales,
                todayOrders: todayOrders,
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

typedef $$LocalStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStatsTable,
      LocalStat,
      $$LocalStatsTableFilterComposer,
      $$LocalStatsTableOrderingComposer,
      $$LocalStatsTableAnnotationComposer,
      $$LocalStatsTableCreateCompanionBuilder,
      $$LocalStatsTableUpdateCompanionBuilder,
      (LocalStat, BaseReferences<_$AppDatabase, $LocalStatsTable, LocalStat>),
      LocalStat,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalVendorOrdersTableTableManager get localVendorOrders =>
      $$LocalVendorOrdersTableTableManager(_db, _db.localVendorOrders);
  $$LocalVendorProfileTableTableManager get localVendorProfile =>
      $$LocalVendorProfileTableTableManager(_db, _db.localVendorProfile);
  $$LocalProductTableTableManager get localProduct =>
      $$LocalProductTableTableManager(_db, _db.localProduct);
  $$LocalStatsTableTableManager get localStats =>
      $$LocalStatsTableTableManager(_db, _db.localStats);
}
