import '../repositories/cart_repository.dart';

class AddToCartUseCase {
  AddToCartUseCase(this._repository);
  final CartRepository _repository;

  Future<void> call({
    required String userId,
    required String productId,
    int quantity = 1,
    String? selectedSize,
  }) {
    return _repository.addItem(
      userId,
      productId,
      quantity: quantity,
      selectedSize: selectedSize,
    );
  }
}
