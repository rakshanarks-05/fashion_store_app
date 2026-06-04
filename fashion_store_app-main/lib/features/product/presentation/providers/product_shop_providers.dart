import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_catalog.dart';
import '../models/shop_for_audience.dart';
import 'home_for_audience_provider.dart';
import 'product_providers.dart';

/// Shop home catalog derived from Firestore products + chip selection.
final shopCatalogProvider = Provider<AsyncValue<ShopCatalog>>((ref) {
  final asyncProducts = ref.watch(productListProvider);
  final asyncCategories = ref.watch(categoryIdToNameProvider);
  final asyncGender = ref.watch(categoryIdToGenderProvider);
  final filterIndex = ref.watch(categoryFilterIndexProvider);
  final forAudience = ref.watch(homeForAudienceProvider);

  final idToName = asyncCategories.valueOrNull ?? <String, String>{};
  final idToGender = asyncGender.valueOrNull ?? <String, String>{};

  return asyncProducts.when(
    data: (all) {
      final chips = ShopCatalog.shopFilterChipsFor(all, idToName);
      final byFor = filterProductsByShopForAudience(
        products: all,
        forAudience: forAudience,
        categoryIdToGender: idToGender,
      );
      if (filterIndex <= 0 || filterIndex >= chips.labels.length) {
        return AsyncValue.data(
          ShopCatalog.fromFirestoreProducts(
            sectionProducts: byFor,
            metaProducts: all,
            categoryIdToName: idToName,
          ),
        );
      }
      final categoryId = chips.categoryIds[filterIndex];
      if (categoryId == null) {
        return AsyncValue.data(
          ShopCatalog.fromFirestoreProducts(
            sectionProducts: byFor,
            metaProducts: all,
            categoryIdToName: idToName,
          ),
        );
      }
      final section = byFor
          .where((p) => p.categoryId == categoryId)
          .toList(growable: false);
      return AsyncValue.data(
        ShopCatalog.fromFirestoreProducts(
          sectionProducts: section,
          metaProducts: all,
          categoryIdToName: idToName,
        ),
      );
    },
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Selected chip index in [CategoryFilterBar] (labels come from live catalog).
final categoryFilterIndexProvider = StateProvider<int>((ref) => 0);
