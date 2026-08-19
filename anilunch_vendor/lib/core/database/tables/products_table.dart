import 'package:drift/drift.dart';

// LocalProduct caches the vendor's menu (meal_products) for instant
// rendering on the dashboard.
class LocalProduct extends Table {
  TextColumn get id => text()(); // Product id
  TextColumn get vendorId => text().nullable()();
  TextColumn get name => text().withDefault(const Constant(''))();
  RealColumn get price => real().nullable()();
  TextColumn get payload => text()(); // Raw product row JSON
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}