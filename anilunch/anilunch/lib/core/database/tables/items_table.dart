import 'package:drift/drift.dart';

// LocalItems stores cached food catalog items for instant, offline-first reads.
class LocalItems extends Table {
  TextColumn get id => text()();
  TextColumn get vendorId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  Int64Column get price => int64()(); // Price in integer paise (₹100 = 10000)
  Int64Column get originalPrice => int64().nullable()();
  TextColumn get category => text()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  IntColumn get prepTime => integer().withDefault(const Constant(20))();
  RealColumn get rating => real().withDefault(const Constant(4.5))();
  IntColumn get reviewsCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
