import 'package:drift/drift.dart';

// LocalRiderProfile caches the rider's own profile row so cold starts
// can render instantly instead of blocking on the network.
class LocalRiderProfile extends Table {
  TextColumn get id => text()(); // Supabase auth user id
  TextColumn get payload => text()(); // JSON snapshot of the riders row
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}