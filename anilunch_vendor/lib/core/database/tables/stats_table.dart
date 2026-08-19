import 'package:drift/drift.dart';

// LocalStats caches the dashboard summary (today's sales + orders) so the
// dashboard renders numbers instantly while the network refreshes.
class LocalStats extends Table {
  TextColumn get vendorId => text()(); // Vendor id
  RealColumn get todaySales => real().withDefault(const Constant(0))();
  IntColumn get todayOrders => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {vendorId};
}