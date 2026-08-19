// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalAdminCacheTable extends LocalAdminCache
    with TableInfo<$LocalAdminCacheTable, LocalAdminCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAdminCacheTable(this.attachedDatabase, [this._alias]);
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
  List<GeneratedColumn> get $columns => [entityType, id, payload, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_admin_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAdminCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
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
  Set<GeneratedColumn> get $primaryKey => {entityType, id};
  @override
  LocalAdminCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAdminCacheData(
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
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
  $LocalAdminCacheTable createAlias(String alias) {
    return $LocalAdminCacheTable(attachedDatabase, alias);
  }
}

class LocalAdminCacheData extends DataClass
    implements Insertable<LocalAdminCacheData> {
  final String entityType;
  final String id;
  final String payload;
  final DateTime updatedAt;
  const LocalAdminCacheData({
    required this.entityType,
    required this.id,
    required this.payload,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_type'] = Variable<String>(entityType);
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalAdminCacheCompanion toCompanion(bool nullToAbsent) {
    return LocalAdminCacheCompanion(
      entityType: Value(entityType),
      id: Value(id),
      payload: Value(payload),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalAdminCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAdminCacheData(
      entityType: serializer.fromJson<String>(json['entityType']),
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityType': serializer.toJson<String>(entityType),
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalAdminCacheData copyWith({
    String? entityType,
    String? id,
    String? payload,
    DateTime? updatedAt,
  }) => LocalAdminCacheData(
    entityType: entityType ?? this.entityType,
    id: id ?? this.id,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalAdminCacheData copyWithCompanion(LocalAdminCacheCompanion data) {
    return LocalAdminCacheData(
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAdminCacheData(')
          ..write('entityType: $entityType, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityType, id, payload, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAdminCacheData &&
          other.entityType == this.entityType &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt);
}

class LocalAdminCacheCompanion extends UpdateCompanion<LocalAdminCacheData> {
  final Value<String> entityType;
  final Value<String> id;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalAdminCacheCompanion({
    this.entityType = const Value.absent(),
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAdminCacheCompanion.insert({
    required String entityType,
    required String id,
    required String payload,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       id = Value(id),
       payload = Value(payload);
  static Insertable<LocalAdminCacheData> custom({
    Expression<String>? entityType,
    Expression<String>? id,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityType != null) 'entity_type': entityType,
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAdminCacheCompanion copyWith({
    Value<String>? entityType,
    Value<String>? id,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalAdminCacheCompanion(
      entityType: entityType ?? this.entityType,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
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
    return (StringBuffer('LocalAdminCacheCompanion(')
          ..write('entityType: $entityType, ')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalAdminCacheTable localAdminCache = $LocalAdminCacheTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localAdminCache];
}

typedef $$LocalAdminCacheTableCreateCompanionBuilder =
    LocalAdminCacheCompanion Function({
      required String entityType,
      required String id,
      required String payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalAdminCacheTableUpdateCompanionBuilder =
    LocalAdminCacheCompanion Function({
      Value<String> entityType,
      Value<String> id,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalAdminCacheTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAdminCacheTable> {
  $$LocalAdminCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

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

class $$LocalAdminCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAdminCacheTable> {
  $$LocalAdminCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

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

class $$LocalAdminCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAdminCacheTable> {
  $$LocalAdminCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalAdminCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAdminCacheTable,
          LocalAdminCacheData,
          $$LocalAdminCacheTableFilterComposer,
          $$LocalAdminCacheTableOrderingComposer,
          $$LocalAdminCacheTableAnnotationComposer,
          $$LocalAdminCacheTableCreateCompanionBuilder,
          $$LocalAdminCacheTableUpdateCompanionBuilder,
          (
            LocalAdminCacheData,
            BaseReferences<
              _$AppDatabase,
              $LocalAdminCacheTable,
              LocalAdminCacheData
            >,
          ),
          LocalAdminCacheData,
          PrefetchHooks Function()
        > {
  $$LocalAdminCacheTableTableManager(
    _$AppDatabase db,
    $LocalAdminCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAdminCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAdminCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAdminCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityType = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAdminCacheCompanion(
                entityType: entityType,
                id: id,
                payload: payload,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityType,
                required String id,
                required String payload,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAdminCacheCompanion.insert(
                entityType: entityType,
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

typedef $$LocalAdminCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAdminCacheTable,
      LocalAdminCacheData,
      $$LocalAdminCacheTableFilterComposer,
      $$LocalAdminCacheTableOrderingComposer,
      $$LocalAdminCacheTableAnnotationComposer,
      $$LocalAdminCacheTableCreateCompanionBuilder,
      $$LocalAdminCacheTableUpdateCompanionBuilder,
      (
        LocalAdminCacheData,
        BaseReferences<
          _$AppDatabase,
          $LocalAdminCacheTable,
          LocalAdminCacheData
        >,
      ),
      LocalAdminCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalAdminCacheTableTableManager get localAdminCache =>
      $$LocalAdminCacheTableTableManager(_db, _db.localAdminCache);
}
