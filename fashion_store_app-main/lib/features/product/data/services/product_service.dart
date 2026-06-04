import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Firestore-backed product access for the shop home.
///
/// Uses the existing [ProductRepository] (real-time `products` collection
/// snapshots). Search/filtering runs in memory on this stream so we do not
/// issue extra reads per keystroke.
class ProductService {
  ProductService(this._repository);

  final ProductRepository _repository;

  /// Live list from Firestore `products` (sorted by `createdAt` in datasource).
  Stream<List<Product>> watchProducts() => _repository.watchAllProducts();
}
