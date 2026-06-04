import '../../domain/entities/order_model.dart';
import '../../domain/repositories/order_repository.dart';
import '../services/order_service.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);
  final OrderService _remote;

  @override
  Future<List<OrderModel>> getOrdersForUser(String userId) {
    return _remote.getUserOrders(userId);
  }
}
