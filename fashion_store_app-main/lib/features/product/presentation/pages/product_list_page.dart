import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/product_network_image.dart';
import '../theme/shop_tokens.dart';
import '../models/shop_catalog.dart';
import '../providers/product_providers.dart';
import '../widgets/add_to_cart_sheet.dart';
import '../widgets/search_bar_widget.dart';

/// Firestore-backed product list with thumbnails and add-to-cart.
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _query) return;
      setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(filteredProductsProvider);
    final categoryMap =
        ref.watch(categoryIdToNameProvider).valueOrNull ?? const <String, String>{};

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            ),
          ),
        ],
      ),
      body: async.when(
        data: (products) {
          final q = _query.toLowerCase();
          final filtered = q.isEmpty
              ? products
              : products.where((p) {
                  final name = p.name.toLowerCase();
                  final cat = p.categoryId.toLowerCase();
                  return name.contains(q) || cat.contains(q);
                }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ShopTokens.screenHorizontal,
                  12,
                  ShopTokens.screenHorizontal,
                  8,
                ),
                child: SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search products...',
                  autofocus: false,
                  onClear: () => setState(() => _query = ''),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          products.isEmpty
                              ? 'No products yet. Add items in Admin.'
                              : 'No results for “$_query”.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final categoryName =
                              categoryMap[p.categoryId]?.trim().isNotEmpty == true
                                  ? categoryMap[p.categoryId]!
                                  : p.categoryId;
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              ShopTokens.screenHorizontal,
                              10,
                              ShopTokens.screenHorizontal,
                              0,
                            ),
                            child: Card(
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    ShopTokens.imageRadius,
                                  ),
                                  child: ProductNetworkImage(
                                    imageUrl: p.imageUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    cloudinaryVariant: CloudinaryVariant.thumbnail,
                                  ),
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  '${categoryName.isEmpty ? '—' : categoryName} · '
                                  '${CurrencyFormat.format(p.price)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.add_shopping_cart_outlined,
                                  ),
                                  tooltip: 'Add to cart',
                                  onPressed: () async {
                                    final shopItem = ShopCatalog.productToShopItem(p);
                                    final imageUrls = p.images
                                        .map((image) => image.imageUrl.trim())
                                        .where((url) => url.isNotEmpty)
                                        .toList(growable: false);
                                    await showAddToCartSheetIfSignedIn(
                                      context,
                                      ref,
                                      product: shopItem,
                                      productImageUrls: imageUrls,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
