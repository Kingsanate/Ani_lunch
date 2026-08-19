import 'package:drift/drift.dart';

// SyncQueue persists pending background mutations to guarantee at-least-once
// delivery for safe ops (online status, GPS location) made while offline.
class SyncQueue extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get entityType => text()(); // 'rider'
  TextColumn get entityId => text()(); // rider id
  TextColumn get action => text()(); // 'update_online', 'update_location'
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