import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_catalog.dart';
import '../providers/home_search_providers.dart';
import '../providers/product_providers.dart';
import '../providers/product_shop_providers.dart';
import '../theme/shop_tokens.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/product_grid_widget.dart';
import '../widgets/product_search_empty_state.dart';
import '../providers/home_for_audience_provider.dart';
import '../providers/home_price_filter_provider.dart';
import '../utils/home_filter_utils.dart';
import '../widgets/home_filter_drawer.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/shop_bottom_navigation_bar.dart';
import '../widgets/add_to_cart_sheet.dart';

/// Fashion shop home: search, banners, categories, carousels, flash sale, grids.
///
/// Uses a plain [StatefulWidget] shell so [ref.watch] in the body does not rebuild
/// [Scaffold.bottomNavigationBar] on every catalog/search update.
class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  void _onNavTap(int index) {
    final nav = Navigator.of(context);
    switch (index) {
      case 0:
        break;
      case 1:
        nav.pushNamed('/wishlist');
        break;
      case 2:
        nav.pushNamed('/orders');
        break;
      case 3:
        nav.pushNamed('/cart');
        break;
      case 4:
        nav.pushNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerW =
        (MediaQuery.sizeOf(context).width * 0.72).clamp(240.0, 320.0);
    return Scaffold(
      endDrawer: Drawer(
        width: drawerW,
        child: const HomeFilterDrawer(),
      ),
      bottomNavigationBar: ShopHomeBottomNavigationBar(
        currentIndex: 0,
        onTap: _onNavTap,
      ),
      body: const SafeArea(
        bottom: false,
        child: _ProductHomeBody(),
      ),
    );
  }
}

/// Riverpod-driven home content only (keeps bottom nav from rebuilding on each watch).
class _ProductHomeBody extends ConsumerWidget {
  const _ProductHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCatalog = ref.watch(shopCatalogProvider);
    final searchQuery = ref.watch(homeSearchQueryProvider);
    final searchItemsAsync = ref.watch(homeSearchShopItemsProvider);
    final priceFilter = ref.watch(homePriceRangeFilterProvider);

    Future<void> openAddToCart(ShopProductItem product) {
      final imageUrls = ref.read(productImageUrlsByIdProvider(product.id));
      return showAddToCartSheetIfSignedIn(
        context,
        ref,
        product: product,
        productImageUrls: imageUrls,
      );
    }

    return asyncCatalog.when(
      data: (catalog) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productListProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _ShopHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(
              child: CategoryFilterBar(
                labels: catalog.filterLabels,
                categoryIds: catalog.filterCategoryIds,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            if (searchQuery.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ShopTokens.screenHorizontal,
                ),
                sliver: SliverToBoxAdapter(
                  child: searchItemsAsync.when(
                    data: (items) => items.isEmpty
                        ? const ProductSearchEmptyState()
                        : ProductGridWidget(
                            items: items,
                            onAddToCart: openAddToCart,
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load results: $e'),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ] else ...[
              SliverToBoxAdapter(
                child: _FeaturedHeader(
                  onMoreTap: () => Navigator.of(context).pushNamed('/browse'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ShopTokens.screenHorizontal,
                ),
                sliver: SliverToBoxAdapter(
                  child: ProductGridWidget(
                    items: filterShopItemsByHomePriceRange(
                      catalog.justForYou,
                      priceFilter,
                    ).take(4).toList(growable: false),
                    onAddToCart: openAddToCart,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load shop: $e')),
    );
  }
}

class _ShopHeader extends ConsumerStatefulWidget {
  const _ShopHeader();

  @override
  ConsumerState<_ShopHeader> createState() => _ShopHeaderState();
}

class _ShopHeaderState extends ConsumerState<_ShopHeader> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(homeSearchQueryProvider, (previous, next) {
      if (next.isEmpty && _searchController.text.isNotEmpty) {
        _searchController.clear();
      }
    });

    final categoryIndex = ref.watch(categoryFilterIndexProvider);
    final priceFilter = ref.watch(homePriceRangeFilterProvider);
    final forAudience = ref.watch(homeForAudienceProvider);
    final filterCount = homeAppliedFilterCount(
      forAudience: forAudience,
      categoryFilterIndex: categoryIndex,
      priceRangeFilter: priceFilter,
    );

    /// Wide enough for bold 20px "Home" on all text scales (48px caused "Hom"/"e" wrap).
    const titleSlotW = 64.0;
    const filterSlotW = 52.0;
    const searchMaxW = 260.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShopTokens.screenHorizontal,
        8,
        ShopTokens.screenHorizontal,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: titleSlotW,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Home',
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      height: 1.1,
                      color: ShopTokens.textPrimary,
                    ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: searchMaxW),
                child: SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search',
                  autofocus: false,
                  onChanged: (q) =>
                      ref.read(homeSearchQueryProvider.notifier).onQueryChanged(q),
                  onSubmitted: (q) =>
                      ref.read(homeSearchQueryProvider.notifier).onQueryChanged(q),
                  onClear: () => ref.read(homeSearchQueryProvider.notifier).clear(),
                ),
              ),
            ),
          ),
          SizedBox(
            width: filterSlotW,
            child: Align(
              alignment: Alignment.centerRight,
              child: Badge(
                isLabelVisible: filterCount > 0,
                backgroundColor: ShopTokens.filterBadge,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                label: Text(
                  '$filterCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  iconSize: 22,
                  tooltip: 'Filters',
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: ShopTokens.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedHeader extends StatelessWidget {
  const _FeaturedHeader({required this.onMoreTap});

  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShopTokens.screenHorizontal),
      child: Row(
        children: [
          const Text(
            'Featured',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ShopTokens.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onMoreTap,
            style: TextButton.styleFrom(
              foregroundColor: ShopTokens.textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('More'),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

