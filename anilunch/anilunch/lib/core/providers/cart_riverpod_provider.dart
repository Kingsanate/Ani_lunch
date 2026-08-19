import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

// cartItemsStreamProvider emits reactive updates whenever local SQLite cart changes.
final cartItemsStreamProvider = StreamProvider<List<LocalCartItem>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCartItems();
});

// cartTotalPaiseProvider calculates total price in integer paise from local cart items.
final cartTotalPaiseProvider = Provider<BigInt>((ref) {
  final cartAsync = ref.watch(cartItemsStreamProvider);
  return cartAsync.when(
    data: (items) {
      return items.fold<BigInt>(
        BigInt.zero,
        (sum, item) => sum + (item.price * BigInt.from(item.quantity)),
      );
    },
    loading: () => BigInt.zero,
    error: (_, __) => BigInt.zero,
  );
});

// cartItemCountProvider returns total item count in cart.
final cartItemCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartItemsStreamProvider);
  return cartAsync.when(
    data: (items) => items.fold<int>(0, (count, item) => count + item.quantity),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// cartControllerProvider provides mutation operations with client UUID generation.
final cartControllerProvider = Provider<CartController>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CartController(db);
});

class CartController {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CartController(this._db);

  // Instant local insert with client-generated UUID
  Future<void> addItem({
    required String itemId,
    required String name,
    required int pricePaise,
    int quantity = 1,
    String? imageUrl,
    String? selectedSpice,
    String? selectedPortion,
    String? specialNotes,
  }) async {
    final companion = LocalCartItemsCompanion(
      id: Value(_uuid.v4()), // Client-side generated UUID
      itemId: Value(itemId),
      name: Value(name),
      price: Value(BigInt.from(pricePaise)),
      quantity: Value(quantity),
      imageUrl: Value(imageUrl),
      selectedSpice: Value(selectedSpice),
      selectedPortion: Value(selectedPortion),
      specialNotes: Value(specialNotes),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    await _db.addToCart(companion);
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    await _db.updateCartQuantity(cartItemId, newQuantity);
  }

  Future<void> removeItem(String cartItemId) async {
    await _db.removeFromCart(cartItemId);
  }

  Future<void> clearCart() async {
    await _db.clearCart();
  }
}
