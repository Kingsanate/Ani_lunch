import 'package:drift/drift.dart';

// SyncQueue persists pending background mutations to guarantee at-least-once delivery.
class SyncQueue extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get entityType => text()(); // 'order', 'cart', 'review', 'profile'
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  TextColumn get payload => text()(); // JSON string
  TextColumn get idempotencyKey => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, in_progress, completed, failed
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
