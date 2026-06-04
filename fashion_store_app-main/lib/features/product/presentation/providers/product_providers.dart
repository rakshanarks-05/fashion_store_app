import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/services/product_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products_usecase.dart';

final productRemoteDataSourceProvider =
    Provider<ProductRemoteDataSource>((ref) {
  return ProductRemoteDataSourceImpl(ref.watch(firebaseFirestoreProvider));
});

final categoryRemoteDataSourceProvider =
    Provider<CategoryRemoteDataSource>((ref) {
  return CategoryRemoteDataSourceImpl(ref.watch(firebaseFirestoreProvider));
});

/// Real-time map of `categories/{id}` document id → `name` (for shop UI labels).
final categoryIdToNameProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(categoryRemoteDataSourceProvider).watchCategoryIdToName();
});

/// Real-time map of `categories/{id}` document id → `gender` (`male` / `female` / `both` / `kids`).
final categoryIdToGenderProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(categoryRemoteDataSourceProvider).watchCategoryIdToGender();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider));
});

/// Single Firestore subscription for the shop; search filters this stream in memory.
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.watch(productRepositoryProvider));
});

final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  return GetProductsUseCase(ref.watch(productRepositoryProvider));
});

/// Live catalog from Firestore `products` (real-time snapshots).
final productListProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productServiceProvider).watchProducts();
});

/// Same data as [productListProvider] for callers that prefer this name.
final productsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productListProvider);
});

final productCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Gallery image urls for a given product id (trimmed, non-empty).
final productImageUrlsByIdProvider =
    Provider.family<List<String>, String>((ref, productId) {
  final products = ref.watch(productListProvider).valueOrNull;
  if (products == null || products.isEmpty) return const <String>[];
  for (final product in products) {
    if (product.id != productId) continue;
    final urls = product.images
        .map((image) => image.imageUrl.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    return urls;
  }
  return const <String>[];
});

/// Applies [productCategoryFilterProvider] to the streamed catalog in memory.
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final async = ref.watch(productListProvider);
  final category = ref.watch(productCategoryFilterProvider);
  return async.when(
    data: (list) {
      if (category == null || category.isEmpty) {
        return AsyncValue.data(list);
      }
      final filtered =
          list.where((p) => p.categoryId == category).toList(growable: false);
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
