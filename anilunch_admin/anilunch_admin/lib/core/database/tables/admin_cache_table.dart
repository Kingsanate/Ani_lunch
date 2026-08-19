import 'package:drift/drift.dart';

// LocalAdminCache stores JSON snapshots of admin datasets (orders, riders,
// menu items, deals) so views render instantly on cold start while the
// network refreshes in the background.
class LocalAdminCache extends Table {
  TextColumn get entityType => text()(); // 'orders', 'riders', 'menu_items', 'deals'
  TextColumn get id => text()(); // Row id
  TextColumn get payload => text()(); // Raw row JSON
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {entityType, id};
}