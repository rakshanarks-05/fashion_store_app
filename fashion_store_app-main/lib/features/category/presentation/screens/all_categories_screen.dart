import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product/presentation/theme/shop_tokens.dart';
import '../models/all_categories_models.dart';
import '../providers/all_categories_providers.dart';
import '../widgets/all_categories_header.dart';
import '../widgets/category_products_expanded_list.dart';
import '../widgets/expandable_category_card.dart';
import '../widgets/gender_tab_bar.dart';
import '../widgets/just_for_you_category_row.dart';

/// Full category tree with gender filter, expandable groups, and "Just for You" CTA.
class AllCategoriesScreen extends ConsumerStatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  ConsumerState<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends ConsumerState<AllCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final List<Animation<double>> _itemFades;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _itemFades = List.generate(
      8,
      (i) => CurvedAnimation(
        parent: _entrance,
        curve: Interval(0.08 + i * 0.06, 0.55 + i * 0.05, curve: Curves.easeOutCubic),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GenderTab>(genderTabProvider, (previous, next) {
      ref.read(allCategoriesCatalogProvider).whenData((all) {
        final vis = all.where((c) => c.visibleFor(next)).toList();
        final exp = ref.read(expandedCategoryIdProvider);
        if (exp != null && !vis.any((g) => g.id == exp)) {
          ref.read(expandedCategoryIdProvider.notifier).state =
              vis.isNotEmpty ? vis.first.id : null;
        }
      });
    });

    ref.listen(allCategoriesCatalogProvider, (previous, next) {
      next.whenData((catalog) {
        final tab = ref.read(genderTabProvider);
        final vis = catalog.where((c) => c.visibleFor(tab)).toList();
        final exp = ref.read(expandedCategoryIdProvider);
        if (vis.isEmpty) {
          ref.read(expandedCategoryIdProvider.notifier).state = null;
          return;
        }
        if (exp == null || !vis.any((g) => g.id == exp)) {
          ref.read(expandedCategoryIdProvider.notifier).state = vis.first.id;
        }
      });
    });

    final asyncCatalog = ref.watch(allCategoriesCatalogProvider);
    final tab = ref.watch(genderTabProvider);
    final expandedId = ref.watch(expandedCategoryIdProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: ShopTokens.pageBackground,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: ShopTokens.textPrimary,
              displayColor: ShopTokens.textPrimary,
            ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entrance,
                  curve: const Interval(0, 0.35, curve: Curves.easeOut),
                ),
                child: AllCategoriesHeader(
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entrance,
                  curve: const Interval(0.05, 0.4, curve: Curves.easeOut),
                ),
                child: const GenderTabBar(),
              ),
              Expanded(
                child: asyncCatalog.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => _CatalogErrorState(
                    message: err.toString(),
                    onRetry: () =>
                        ref.invalidate(fetchedCategoriesProvider),
                  ),
                  data: (catalog) {
                    if (catalog.isEmpty) {
                      return const _EmptyCatalogState();
                    }
                    final visible =
                        catalog.where((c) => c.visibleFor(tab)).toList();
                    if (visible.isEmpty) {
                      return const _EmptyFilterState();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        ShopTokens.screenHorizontal,
                        8,
                        ShopTokens.screenHorizontal,
                        24,
                      ),
                      itemCount: visible.length + 1,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == visible.length) {
                          return JustForYouCategoryRow(
                            fadeAnimation: _fadeFor(index),
                            onTap: () => _snack('Open personalized picks'),
                          );
                        }
                        final group = visible[index];
                        final expanded = expandedId == group.id;
                        return ExpandableCategoryCard(
                          group: group,
                          expanded: expanded,
                          fadeAnimation: _fadeFor(index),
                          onToggleExpand: () {
                            ref
                                    .read(expandedCategoryIdProvider.notifier)
                                    .state =
                                expanded ? null : group.id;
                          },
                          expandedBody: expanded
                              ? CategoryProductsExpandedList(
                                  categoryId: group.id,
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Animation<double>? _fadeFor(int index) {
    if (index >= _itemFades.length) {
      return _itemFades.isNotEmpty ? _itemFades.last : null;
    }
    return _itemFades[index];
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No categories for this filter yet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ShopTokens.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No categories available yet.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ShopTokens.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Could not load categories.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ShopTokens.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ShopTokens.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
