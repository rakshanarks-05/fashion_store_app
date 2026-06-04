import '../repositories/cart_repository.dart';

class SetCartItemQuantityUseCase {
  SetCartItemQuantityUseCase(this._repository);
  final CartRepository _repository;

  Future<void> call({
    required String userId,
    required String productId,
    required int quantity,
    String? selectedSize,
  }) {
    if (selectedSize == null) {
      return _repository.setItemQuantity(userId, productId, quantity);
    }
    return _repository.setItemSelection(
      userId,
      productId,
      quantity: quantity,
      selectedSize: selectedSize,
    );
  }
}
