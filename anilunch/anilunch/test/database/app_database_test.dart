import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anilunch/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // In-memory SQLite database for rapid, isolated unit testing
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift SQLite AppDatabase Tests', () {
    test('local cart - add, stream, update quantity, and remove', () async {
      // 1. Add item to cart with client-generated ID
      final item = LocalCartItemsCompanion(
        id: const Value('cart-item-uuid-001'),
        itemId: const Value('food-item-123'),
        name: const Value('Chicken Biryani Bento'),
        price: Value(BigInt.from(14900)), // ₹149.00 in paise
        quantity: const Value(1),
        selectedSpice: const Value('Medium'),
        selectedPortion: const Value('Regular'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      await db.addToCart(item);

      // 2. Verify item in cart
      var cartList = await db.watchCartItems().first;
      expect(cartList.length, 1);
      expect(cartList.first.id, 'cart-item-uuid-001');
      expect(cartList.first.name, 'Chicken Biryani Bento');
      expect(cartList.first.price, BigInt.from(14900));
      expect(cartList.first.quantity, 1);

      // 3. Adding same item increases quantity
      await db.addToCart(item);
      cartList = await db.watchCartItems().first;
      expect(cartList.length, 1);
      expect(cartList.first.quantity, 2);

      // 4. Update quantity
      await db.updateCartQuantity('cart-item-uuid-001', 3);
      cartList = await db.watchCartItems().first;
      expect(cartList.first.quantity, 3);

      // 5. Remove from cart
      await db.removeFromCart('cart-item-uuid-001');
      cartList = await db.watchCartItems().first;
      expect(cartList.isEmpty, true);
    });

    test('catalog items - upsert and reactive streaming', () async {
      final items = [
        LocalItemsCompanion(
          id: const Value('item-1'),
          name: const Value('Grilled Salmon Salad'),
          price: Value(BigInt.from(24900)),
          category: const Value('Salads'),
          isAvailable: const Value(true),
          rating: const Value(4.8),
          prepTime: const Value(15),
          reviewsCount: const Value(42),
          syncedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        LocalItemsCompanion(
          id: const Value('item-2'),
          name: const Value('Teriyaki Chicken Bowl'),
          price: Value(BigInt.from(18900)),
          category: const Value('Bowls'),
          isAvailable: const Value(true),
          rating: const Value(4.6),
          prepTime: const Value(20),
          reviewsCount: const Value(18),
          syncedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ];

      await db.upsertItems(items);

      final allItems = await db.watchAllItems().first;
      expect(allItems.length, 2);
      expect(allItems.first.name, 'Grilled Salmon Salad'); // Higher rating first

      final saladItems = await db.watchItemsByCategory('Salads').first;
      expect(saladItems.length, 1);
      expect(saladItems.first.id, 'item-1');
    });

    test('sync queue - enqueue, retrieve pending, and mark completed', () async {
      final task = SyncQueueCompanion(
        id: const Value('sync-task-001'),
        entityType: const Value('order'),
        entityId: const Value('order-uuid-999'),
        action: const Value('create'),
        payload: const Value('{"id":"order-uuid-999","total_amount":35000}'),
        idempotencyKey: const Value('idem-key-abc-123'),
        status: const Value('pending'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      await db.enqueueSyncTask(task);

      var pending = await db.getPendingSyncTasks();
      expect(pending.length, 1);
      expect(pending.first.id, 'sync-task-001');
      expect(pending.first.entityType, 'order');
      expect(pending.first.idempotencyKey, 'idem-key-abc-123');

      // Mark completed
      await db.markSyncTaskCompleted('sync-task-001');
      pending = await db.getPendingSyncTasks();
      expect(pending.isEmpty, true);
    });
  });
}
