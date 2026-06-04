import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product/presentation/providers/category_browse_providers.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../product/presentation/models/shop_catalog.dart';
import '../../../product/presentation/widgets/product_list_row_card.dart';
import '../../../product/presentation/widgets/product_search_empty_state.dart';
import '../../../product/presentation/widgets/add_to_cart_sheet.dart';

/// Products for a Firestore category, shown under an expanded category row.
class CategoryProductsExpandedList extends ConsumerWidget {
  const CategoryProductsExpandedList({
    super.key,
    required this.categoryId,
  });

  final String categoryId;

  Future<void> _openAddToCartSheet(
    BuildContext context, {
    required WidgetRef ref,
    required ShopProductItem product,
  }) async {
    final imageUrls = ref.read(productImageUrlsByIdProvider(product.id));
    await showAddToCartSheetIfSignedIn(
      context,
      ref,
      product: product,
      productImageUrls: imageUrls,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoryProductsShopItemsProvider(categoryId));

    return async.when(
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 4),
            child: ProductSearchEmptyState(),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              ProductListRowCard(
                product: items[i],
                onAddToCart: () => _openAddToCartSheet(
                  context,
                  ref: ref,
                  product: items[i],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Could not load products: $e',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
