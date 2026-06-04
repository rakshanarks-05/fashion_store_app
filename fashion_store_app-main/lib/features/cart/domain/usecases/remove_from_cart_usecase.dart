import '../repositories/cart_repository.dart';

class RemoveFromCartUseCase {
  RemoveFromCartUseCase(this._repository);
  final CartRepository _repository;

  Future<void> call({
    required String userId,
    required String productId,
  }) {
    return _repository.removeItem(userId, productId);
  }
}
