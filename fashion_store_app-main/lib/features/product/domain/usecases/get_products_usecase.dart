import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsUseCase {
  GetProductsUseCase(this._repository);
  final ProductRepository _repository;

  Future<List<Product>> call({String? category}) {
    return _repository.getProducts(category: category);
  }
}
