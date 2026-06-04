import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  /// Firestore returns [ProductModel]s as `List<ProductModel>`. On web, that
  /// type is not a runtime subtype of `List<Product>` (generic lists are
  /// invariant), which breaks Riverpod / JS interop. Copying fixes the error.
  static List<Product> _asProductList(Iterable<Product> items) =>
      List<Product>.from(items);

  @override
  Future<List<Product>> getProducts({String? category}) async {
    final list = await _remote.fetchProducts(category: category);
    return _asProductList(list);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final list = await _remote.getAllProducts();
    return _asProductList(list);
  }

  @override
  Future<List<Product>> getFeaturedProducts() async {
    final list = await _remote.getFeaturedProducts();
    return _asProductList(list);
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    final list = await _remote.getProductsByCategory(category);
    return _asProductList(list);
  }

  @override
  Stream<List<Product>> watchAllProducts() {
    return _remote.watchAllProducts().map(_asProductList);
  }

  @override
  Stream<List<Product>> watchFeaturedProducts() {
    return _remote.watchFeaturedProducts().map(_asProductList);
  }

  @override
  Stream<List<Product>> watchProductsByCategory(String category) {
    return _remote.watchProductsByCategory(category).map(_asProductList);
  }
}
