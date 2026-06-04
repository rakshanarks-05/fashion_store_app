import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firestore_create/models/category_document.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../data/category_service.dart';
import '../models/all_categories_models.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(firebaseFirestoreProvider));
});

/// Current user gender for catalog filtering: `"male"` or `"female"`.
/// Wire this to profile/auth when available (independent of [genderTabProvider]).
final currentUserCatalogGenderProvider = Provider<String>((ref) => 'female');

/// Firestore categories for the All Categories screen (invalidate on retry).
final fetchedCategoriesProvider = FutureProvider<List<CategoryDocument>>((ref) async {
  final userGender = ref.watch(currentUserCatalogGenderProvider);
  final service = ref.watch(categoryServiceProvider);
  return service.fetchCategoriesForUser(userGender);
});

/// Category rows for All Categories, with thumbnails taken from each category’s
/// chronologically first product when available; otherwise [CategoryDocument.imageUrl].
final allCategoriesCatalogProvider =
    Provider<AsyncValue<List<CatalogCategoryGroup>>>((ref) {
  final docsAsync = ref.watch(fetchedCategoriesProvider);
  final productsAsync = ref.watch(productListProvider);

  return docsAsync.when(
    data: (docs) {
      final groups = docs
          .map(
            (CategoryDocument d) => CatalogCategoryGroup(
              id: d.id,
              name: d.name,
              imageUrl: d.imageUrl,
              subcategories: const [],
              audience: categoryAudienceFromGender(d.gender),
            ),
          )
          .toList();

      return productsAsync.when(
        data: (products) => AsyncValue.data(
          _categoryGroupsWithProductThumbnails(groups, products),
        ),
        loading: () => AsyncValue.data(groups),
        error: (err, stack) => AsyncValue.data(groups),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

List<CatalogCategoryGroup> _categoryGroupsWithProductThumbnails(
  List<CatalogCategoryGroup> groups,
  List<Product> products,
) {
  final sorted = [...products]..sort((a, b) {
      final ca = a.createdAt;
      final cb = b.createdAt;
      if (ca == null && cb == null) return a.id.compareTo(b.id);
      if (ca == null) return 1;
      if (cb == null) return -1;
      return ca.compareTo(cb);
    });

  final firstProductByCategoryId = <String, Product>{};
  for (final p in sorted) {
    final cid = p.categoryId.trim();
    if (cid.isEmpty) continue;
    firstProductByCategoryId.putIfAbsent(cid, () => p);
  }

  return groups.map((g) {
    final p = firstProductByCategoryId[g.id];
    final thumb = p != null && p.imageUrl.trim().isNotEmpty
        ? p.imageUrl.trim()
        : g.imageUrl;
    return CatalogCategoryGroup(
      id: g.id,
      name: g.name,
      imageUrl: thumb,
      subcategories: g.subcategories,
      audience: g.audience,
    );
  }).toList();
}

/// Selected gender tab: All · Female · Male (defaults to All).
final genderTabProvider = StateProvider<GenderTab>((ref) => GenderTab.all);

/// At most one expanded group; `null` means all collapsed.
final expandedCategoryIdProvider = StateProvider<String?>((ref) => null);
