import 'package:drift/drift.dart';

// LocalOrders caches the rider's order feed locally so screens render
// instantly (cache-first) while the network refreshes in the background.
class LocalOrders extends Table {
  TextColumn get id => text()(); // Server order id
  TextColumn get status => text().withDefault(const Constant(''))();
  TextColumn get riderId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerAddress => text().nullable()();
  RealColumn get customerLat => real().nullable()();
  RealColumn get customerLng => real().nullable()();
  RealColumn get restaurantLat => real().nullable()();
  RealColumn get restaurantLng => real().nullable()();
  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();
  RealColumn get totalAmount => real().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}