import '../../domain/entities/product.dart';
import '../models/shop_catalog.dart';

/// Category chip filter (same semantics as [shopCatalogProvider]).
List<Product> applyCategoryChipFilter({
  required List<Product> all,
  required int filterIndex,
  required Map<String, String> categoryIdToName,
}) {
  final chips = ShopCatalog.shopFilterChipsFor(all, categoryIdToName);
  if (filterIndex <= 0 || filterIndex >= chips.labels.length) return all;
  final categoryId = chips.categoryIds[filterIndex];
  if (categoryId == null) return all;
  return all.where((p) => p.categoryId == categoryId).toList(growable: false);
}

/// Case-insensitive partial match on name, description, and resolved category label.
List<Product> filterProductsBySearchQuery({
  required List<Product> products,
  required String query,
  required Map<String, String> categoryIdToName,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return products;
  final q = trimmed.toLowerCase();
  return products.where((p) {
    if (p.name.toLowerCase().contains(q)) return true;
    if (p.description.toLowerCase().contains(q)) return true;
    final catLabel = (categoryIdToName[p.categoryId] ?? p.categoryId).trim();
    if (catLabel.isNotEmpty && catLabel.toLowerCase().contains(q)) return true;
    return false;
  }).toList(growable: false);
}
