import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._remote);
  final CartRemoteDataSource _remote;

  @override
  Future<void> addItem(
    String userId,
    String productId, {
    int quantity = 1,
    String? selectedSize,
  }) {
    return _remote.addItem(
      userId,
      productId,
      quantity,
      selectedSize: selectedSize,
    );
  }

  @override
  Future<List<CartItem>> getItems(String userId) {
    return _remote.fetchItems(userId);
  }

  @override
  Future<void> removeItem(String userId, String productId) {
    return _remote.removeItem(userId, productId);
  }

  @override
  Future<void> setItemQuantity(
    String userId,
    String productId,
    int quantity,
  ) {
    return _remote.setItemQuantity(userId, productId, quantity);
  }

  @override
  Future<void> setItemSelection(
    String userId,
    String productId, {
    required int quantity,
    String? selectedSize,
  }) {
    return _remote.setItemSelection(
      userId,
      productId,
      quantity: quantity,
      selectedSize: selectedSize,
    );
  }

  @override
  Future<void> clearCart(String userId) {
    return _remote.clearCart(userId);
  }
}
