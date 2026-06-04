import '../../domain/entities/product.dart';

/// Who the shopper is browsing **for** (fashion home filter).
enum ShopForAudience {
  everyone,
  women,
  men,
  kids,
}

extension ShopForAudienceLabels on ShopForAudience {
  String get filterLabel {
    switch (this) {
      case ShopForAudience.everyone:
        return 'Everyone';
      case ShopForAudience.women:
        return 'Women';
      case ShopForAudience.men:
        return 'Men';
      case ShopForAudience.kids:
        return 'Kids';
    }
  }
}

/// Uses each category’s Firestore `gender` field (`male` / `female` / `both` / `kids`).
///
/// [categoryIdToGender] is `categoryId →` normalized gender; missing ids count as `both`.
/// [categoryId] `null` is the **All** chip and is always allowed.
bool categoryIdMatchesShopFor(
  String? categoryId,
  ShopForAudience forAudience,
  Map<String, String> categoryIdToGender,
) {
  if (forAudience == ShopForAudience.everyone) return true;
  if (categoryId == null || categoryId.isEmpty) return true;

  final g = categoryIdToGender[categoryId] ?? 'both';
  switch (forAudience) {
    case ShopForAudience.everyone:
      return true;
    case ShopForAudience.women:
      return g == 'female' || g == 'both';
    case ShopForAudience.men:
      return g == 'male' || g == 'both';
    case ShopForAudience.kids:
      return g == 'kids' || g == 'both';
  }
}

/// Keeps only products in categories that match [forAudience] per [categoryIdToGender].
List<Product> filterProductsByShopForAudience({
  required List<Product> products,
  required ShopForAudience forAudience,
  required Map<String, String> categoryIdToGender,
}) {
  if (forAudience == ShopForAudience.everyone) return products;
  return products
      .where((p) {
        final id = p.categoryId.trim();
        return categoryIdMatchesShopFor(
          id.isEmpty ? null : id,
          forAudience,
          categoryIdToGender,
        );
      })
      .toList(growable: false);
}
