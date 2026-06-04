import '../entities/order_model.dart';
import '../repositories/order_repository.dart';

class GetOrdersUseCase {
  GetOrdersUseCase(this._repository);
  final OrderRepository _repository;

  Future<List<OrderModel>> call(String userId) {
    return _repository.getOrdersForUser(userId);
  }
}
