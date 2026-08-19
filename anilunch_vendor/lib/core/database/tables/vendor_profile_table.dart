import 'package:drift/drift.dart';

// LocalVendorProfile caches the seller row so the shell can enter instantly
// on cold start instead of blocking on the network.
class LocalVendorProfile extends Table {
  TextColumn get id => text()(); // Supabase auth user id
  TextColumn get payload => text()(); // Raw sellers row JSON
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}