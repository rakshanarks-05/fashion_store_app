import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? category});

  Future<List<Product>> getAllProducts();

  Future<List<Product>> getFeaturedProducts();

  Future<List<Product>> getProductsByCategory(String category);

  Stream<List<Product>> watchAllProducts();

  Stream<List<Product>> watchFeaturedProducts();

  Stream<List<Product>> watchProductsByCategory(String category);
}
