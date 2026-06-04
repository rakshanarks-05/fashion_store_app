import '../repositories/cart_repository.dart';

class ClearCartUseCase {
  ClearCartUseCase(this._repository);
  final CartRepository _repository;

  Future<void> call({required String userId}) => _repository.clearCart(userId);
}
