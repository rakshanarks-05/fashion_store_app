import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../controllers/home_controller.dart';
import '../models/shop_catalog.dart';
import '../models/shop_for_audience.dart';
import '../utils/home_filter_utils.dart';
import 'home_for_audience_provider.dart';
import 'home_price_filter_provider.dart';
import 'product_providers.dart';
import 'product_shop_providers.dart';

/// Debounced search string (400ms). Empty when cleared or whitespace-only.
///
/// Filtering uses the cached [productListProvider] snapshot — no extra Firestore
/// queries when typing.
class HomeSearchNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  static const Duration _debounceDelay = Duration(milliseconds: 400);

  void onQueryChanged(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _debounce?.cancel();
      state = '';
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => state = trimmed);
  }

  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

final homeSearchQueryProvider =
    NotifierProvider<HomeSearchNotifier, String>(HomeSearchNotifier.new);

/// Products after category chips + debounced search (for the home search grid).
final homeSearchFilteredProductsProvider =
    Provider<AsyncValue<List<Product>>>((ref) {
  final async = ref.watch(productListProvider);
  final asyncCategories = ref.watch(categoryIdToNameProvider);
  final asyncGender = ref.watch(categoryIdToGenderProvider);
  final filterIndex = ref.watch(categoryFilterIndexProvider);
  final query = ref.watch(homeSearchQueryProvider);
  final priceRange = ref.watch(homePriceRangeFilterProvider);
  final forAudience = ref.watch(homeForAudienceProvider);

  final idToName = asyncCategories.valueOrNull ?? <String, String>{};
  final idToGender = asyncGender.valueOrNull ?? <String, String>{};

  return async.when(
    data: (all) {
      final byFor = filterProductsByShopForAudience(
        products: all,
        forAudience: forAudience,
        categoryIdToGender: idToGender,
      );
      final byCategory = applyCategoryChipFilter(
        all: byFor,
        filterIndex: filterIndex,
        categoryIdToName: idToName,
      );
      final filtered = filterProductsBySearchQuery(
        products: byCategory,
        query: query,
        categoryIdToName: idToName,
      );
      final byPrice =
          filterProductsByHomePriceRange(filtered, priceRange);
      return AsyncValue.data(byPrice);
    },
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// [ShopProductItem]s for [ProductGridWidget] when search is active.
final homeSearchShopItemsProvider =
    Provider<AsyncValue<List<ShopProductItem>>>((ref) {
  final async = ref.watch(homeSearchFilteredProductsProvider);
  return async.when(
    data: (list) => AsyncValue.data(
      list.map(ShopCatalog.productToShopItem).toList(growable: false),
    ),
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
