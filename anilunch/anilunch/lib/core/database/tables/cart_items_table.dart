import 'package:drift/drift.dart';

// LocalCartItems stores client-authoritative, zero-latency cart items.
class LocalCartItems extends Table {
  TextColumn get id => text()(); // Client-generated UUID
  TextColumn get itemId => text()();
  TextColumn get name => text()();
  Int64Column get price => int64()(); // Price in integer paise
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get selectedSpice => text().nullable()();
  TextColumn get selectedPortion => text().nullable()();
  TextColumn get specialNotes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
