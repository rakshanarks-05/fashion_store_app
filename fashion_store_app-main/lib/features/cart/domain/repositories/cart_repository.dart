import '../entities/cart_item.dart';

abstract class CartRepository {
  Future<void> addItem(
    String userId,
    String productId, {
    int quantity = 1,
    String? selectedSize,
  });

  Future<List<CartItem>> getItems(String userId);

  Future<void> removeItem(String userId, String productId);

  Future<void> setItemQuantity(
    String userId,
    String productId,
    int quantity,
  );

  Future<void> setItemSelection(
    String userId,
    String productId, {
    required int quantity,
    String? selectedSize,
  });

  /// Removes every document under `users/{userId}/cart`.
  Future<void> clearCart(String userId);
}
