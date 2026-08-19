import 'package:drift/drift.dart';

// LocalVendorOrders caches the vendor's order feed (active + history) so the
// orders tab renders instantly on cold start while Supabase streams reconnect.
class LocalVendorOrders extends Table {
  TextColumn get id => text()(); // Server order id
  TextColumn get status => text().withDefault(const Constant(''))();
  TextColumn get vendorId => text().nullable()();
  TextColumn get payload => text()(); // Raw order row JSON (matches UI shape)
  DateTimeColumn get orderTime => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}