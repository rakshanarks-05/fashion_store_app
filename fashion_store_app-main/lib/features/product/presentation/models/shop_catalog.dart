import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency_format.dart';
import '../../domain/entities/product.dart';

class ShopBannerSlide extends Equatable {
  const ShopBannerSlide({
    required this.headline,
    required this.subheadline,
    required this.caption,
    required this.imageUrl,
  });

  final String headline;
  final String subheadline;
  final String caption;
  final String imageUrl;

  @override
  List<Object?> get props => [headline, subheadline, caption, imageUrl];
}

class ShopCategoryTile extends Equatable {
  const ShopCategoryTile({
    required this.id,
    required this.name,
    required this.productCount,
    required this.thumbnailUrls,
  });

  final String id;
  final String name;
  final int productCount;
  final List<String> thumbnailUrls;

  @override
  List<Object?> get props => [id, name, productCount, thumbnailUrls];
}

class ShopProductItem extends Equatable {
  const ShopProductItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.discountPercent,
  });

  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final int? discountPercent;

  @override
  List<Object?> get props => [id, title, imageUrl, price, discountPercent];
}

class ShopPopularItem extends Equatable {
  const ShopPopularItem({
    required this.id,
    required this.imageUrl,
    required this.price,
    required this.tag,
  });

  final String id;
  final String imageUrl;
  final double price;
  final String tag;

  @override
  List<Object?> get props => [id, imageUrl, price, tag];
}

/// Filter chips: [labels] are shown in the UI; [categoryIds] aligns by index
/// (null at 0 = **All**, otherwise Firestore category document id).
class ShopFilterChips extends Equatable {
  const ShopFilterChips({required this.labels, required this.categoryIds});

  final List<String> labels;
  final List<String?> categoryIds;

  @override
  List<Object?> get props => [labels, categoryIds];
}

class ShopCatalog extends Equatable {
  const ShopCatalog({
    required this.banners,
    required this.categories,
    required this.topProductImageUrls,
    required this.filterLabels,
    required this.filterCategoryIds,
    required this.newItems,
    required this.flashSaleItems,
    required this.mostPopular,
    required this.justForYou,
  });

  final List<ShopBannerSlide> banners;
  final List<ShopCategoryTile> categories;
  final List<String> topProductImageUrls;
  final List<String> filterLabels;
  /// Parallel to [filterLabels]; use when filtering products by category id.
  final List<String?> filterCategoryIds;
  final List<ShopProductItem> newItems;
  final List<ShopProductItem> flashSaleItems;
  final List<ShopPopularItem> mostPopular;
  final List<ShopProductItem> justForYou;

  @override
  List<Object?> get props => [
        banners,
        categories,
        topProductImageUrls,
        filterLabels,
        filterCategoryIds,
        newItems,
        flashSaleItems,
        mostPopular,
        justForYou,
      ];

  /// Builds chip labels (names) and parallel Firestore category ids for filtering.
  static ShopFilterChips shopFilterChipsFor(
    Iterable<Product> products,
    Map<String, String> categoryIdToName,
  ) {
    final ids = <String>{};
    for (final p in products) {
      if (p.categoryId.isNotEmpty) ids.add(p.categoryId);
    }
    final pairs = ids.map((id) {
      final display = (categoryIdToName[id] ?? id).trim();
      return MapEntry(id, display.isNotEmpty ? display : id);
    }).toList();
    pairs.sort(
      (a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()),
    );
    return ShopFilterChips(
      labels: ['All', ...pairs.map((e) => e.value)],
      categoryIds: [null, ...pairs.map((e) => e.key)],
    );
  }

  /// Maps Firestore products into the existing shop layout without redesigning UI.
  ///
  /// [metaProducts] drives banners, the category grid, and filter chips (full
  /// catalog). [sectionProducts] drives horizontal rows and grids (optionally
  /// narrowed when a category chip is selected).
  ///
  /// [categoryIdToName] maps `categories/{id}` document id → `name` field for
  /// display on chips and category tiles (falls back to id when missing).
  factory ShopCatalog.fromFirestoreProducts({
    required List<Product> sectionProducts,
    required List<Product> metaProducts,
    Map<String, String> categoryIdToName = const {},
  }) {
    final chips = shopFilterChipsFor(metaProducts, categoryIdToName);
    final filterLabels = chips.labels;
    final filterCategoryIds = chips.categoryIds;
    if (metaProducts.isEmpty) {
      return ShopCatalog(
        banners: const [],
        categories: const [],
        topProductImageUrls: const [],
        filterLabels: filterLabels,
        filterCategoryIds: filterCategoryIds,
        newItems: const [],
        flashSaleItems: const [],
        mostPopular: const [],
        justForYou: const [],
      );
    }

    final metaSorted = [...metaProducts]..sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
    final featured = metaProducts.where((p) => p.isFeatured).toList();

    final bannerSources = featured.length >= 2
        ? featured.take(2).toList()
        : (featured + metaSorted).take(2).toList();
    final banners = <ShopBannerSlide>[
      for (final p in bannerSources)
        if (p.imageUrl.isNotEmpty)
          ShopBannerSlide(
            headline: _shortTitle(p.name, 28),
            subheadline: CurrencyFormat.format(p.price),
            caption: p.categoryId.isNotEmpty
                ? (categoryIdToName[p.categoryId] ?? p.categoryId)
                : 'Shop',
            imageUrl: p.imageUrl,
          ),
    ];

    final categories = <ShopCategoryTile>[];
    for (var i = 1; i < chips.labels.length; i++) {
      final id = chips.categoryIds[i]!;
      final displayName = chips.labels[i];
      final inCat =
          metaProducts.where((p) => p.categoryId == id).toList(growable: false);
      final thumbs = _uniqueCollageUrlsForCategory(inCat, maxCount: 4);
      categories.add(
        ShopCategoryTile(
          id: id,
          name: displayName,
          productCount: inCat.length,
          thumbnailUrls: thumbs,
        ),
      );
    }

    final sectionSorted = [...sectionProducts]..sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
    final sectionFeatured = sectionProducts.where((p) => p.isFeatured).toList();

    final topUrls = <String>[];
    for (final p in sectionFeatured) {
      if (p.imageUrl.isNotEmpty && topUrls.length < 5) topUrls.add(p.imageUrl);
    }
    for (final p in sectionSorted) {
      if (p.imageUrl.isNotEmpty &&
          topUrls.length < 5 &&
          !topUrls.contains(p.imageUrl)) {
        topUrls.add(p.imageUrl);
      }
    }

    final newItems = sectionSorted
        .take(5)
        .map(_toShopProductItem)
        .toList();

    final flashSources = sectionFeatured.length >= 6
        ? sectionFeatured.take(6).toList()
        : (sectionFeatured + sectionSorted).take(6).toList();
    final flashSaleItems = flashSources.map((p) {
      return ShopProductItem(
        id: p.id,
        title: _shortTitle(p.name, 40),
        imageUrl: p.imageUrl,
        price: p.price,
        discountPercent: 20,
      );
    }).toList();

    final popularSources = sectionFeatured.isNotEmpty
        ? sectionFeatured.take(5).toList()
        : sectionSorted.take(5).toList();
    final mostPopular = popularSources
        .map(
          (p) => ShopPopularItem(
            id: p.id,
            imageUrl: p.imageUrl,
            price: p.price,
            tag: p.isFeatured ? 'Hot' : 'New',
          ),
        )
        .toList();

    final justForYou = sectionSorted.map(_toShopProductItem).toList();

    return ShopCatalog(
      banners: banners,
      categories: categories,
      topProductImageUrls: topUrls,
      filterLabels: filterLabels,
      filterCategoryIds: filterCategoryIds,
      newItems: newItems,
      flashSaleItems: flashSaleItems,
      mostPopular: mostPopular,
      justForYou: justForYou,
    );
  }

  static ShopProductItem _toShopProductItem(Product p) {
    return productToShopItem(p);
  }

  /// Maps a domain [Product] to a grid/list tile (same rules as shop sections).
  static ShopProductItem productToShopItem(Product p) {
    return ShopProductItem(
      id: p.id,
      title: _shortTitle(p.name, 48),
      imageUrl: p.imageUrl,
      price: p.price,
      discountPercent: p.isFeatured ? 15 : null,
    );
  }

  static String _shortTitle(String raw, int maxChars) {
    final t = raw.trim();
    if (t.length <= maxChars) return t.isEmpty ? 'Product' : t;
    return '${t.substring(0, maxChars - 1)}…';
  }

  /// Up to [maxCount] **distinct** image URLs for the home category 2×2 collage.
  ///
  /// Walks products newest-first, then each product’s gallery order, and skips
  /// duplicate URLs so quadrants show different assets when available.
  static List<String> _uniqueCollageUrlsForCategory(
    List<Product> inCategory, {
    int maxCount = 4,
  }) {
    final sorted = [...inCategory]..sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
    final seen = <String>{};
    final out = <String>[];
    for (final p in sorted) {
      for (final img in p.images) {
        final u = img.imageUrl.trim();
        if (u.isEmpty) continue;
        if (seen.add(u)) {
          out.add(u);
          if (out.length >= maxCount) return out;
        }
      }
    }
    return out;
  }
}
