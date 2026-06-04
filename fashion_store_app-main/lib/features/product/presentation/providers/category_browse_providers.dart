import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_catalog.dart';
import 'product_providers.dart';

/// Products in a Firestore category ([Product.categoryId] == [categoryId]) as grid items.
final categoryProductsShopItemsProvider =
    Provider.family<AsyncValue<List<ShopProductItem>>, String>((ref, categoryId) {
  final async = ref.watch(productListProvider);
  return async.when(
    data: (all) {
      final filtered = all
          .where((p) => p.categoryId == categoryId)
          .toList(growable: false);
      final items =
          filtered.map(ShopCatalog.productToShopItem).toList(growable: false);
      return AsyncValue.data(items);
    },
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
