import 'package:drift/drift.dart';

// LocalOrders stores client-side orders with offline drafts and sync tracking.
class LocalOrders extends Table {
  TextColumn get id => text()(); // Client UUID or server ID
  TextColumn get userId => text()();
  TextColumn get vendorId => text().nullable()();
  TextColumn get riderId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  Int64Column get subtotal => int64()(); // In integer paise
  Int64Column get deliveryFee => int64()();
  Int64Column get discount => int64().withDefault(Constant(BigInt.zero))();
  Int64Column get totalAmount => int64()();
  TextColumn get couponCode => text().nullable()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cod'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  TextColumn get deliveryStreet => text().withDefault(const Constant(''))();
  TextColumn get deliveryCity => text().withDefault(const Constant(''))();
  TextColumn get deliveryZip => text().withDefault(const Constant(''))();
  RealColumn get deliveryLat => real().nullable()();
  RealColumn get deliveryLng => real().nullable()();
  TextColumn get specialNotes => text().nullable()();
  TextColumn get idempotencyKey => text()(); // Client-generated UUID for deduplication
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending, synced, failed
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
