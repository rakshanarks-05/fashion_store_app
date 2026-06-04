import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_catalog.dart';
import '../models/shop_for_audience.dart';
import '../providers/home_for_audience_provider.dart';
import '../providers/home_price_filter_provider.dart';
import '../providers/product_providers.dart';
import '../providers/product_shop_providers.dart';
import '../theme/shop_tokens.dart';
import '../utils/home_filter_utils.dart';

/// End-drawer: category chips + price range. Changes apply only when **Apply** is pressed.
class HomeFilterDrawer extends ConsumerStatefulWidget {
  const HomeFilterDrawer({super.key});

  static const Color _accent = Color(0xFFF07D74);

  @override
  ConsumerState<HomeFilterDrawer> createState() => _HomeFilterDrawerState();
}

class _HomeFilterDrawerState extends ConsumerState<HomeFilterDrawer> {
  late ShopForAudience _draftForAudience;
  late int _draftCategoryIndex;
  /// Draft slider values; updated when the user moves the range thumbs.
  RangeValues? _draftPriceRange;

  @override
  void initState() {
    super.initState();
    _draftForAudience = ref.read(homeForAudienceProvider);
    _draftCategoryIndex = ref.read(categoryFilterIndexProvider);
    _draftPriceRange = ref.read(homePriceRangeFilterProvider);
  }

  RangeValues _displayRange(({double min, double max}) bounds) {
    final d = _draftPriceRange;
    if (d == null) return RangeValues(bounds.min, bounds.max);
    final a = d.start.clamp(bounds.min, bounds.max);
    final b = d.end.clamp(bounds.min, bounds.max);
    return a <= b ? RangeValues(a, b) : RangeValues(bounds.min, bounds.max);
  }

  void _resetDraft() {
    final all = ref.read(productListProvider).valueOrNull;
    final b =
        all == null ? null : homePriceBoundsFromProducts(all);
    setState(() {
      _draftForAudience = ShopForAudience.everyone;
      _draftCategoryIndex = 0;
      _draftPriceRange = b != null ? RangeValues(b.min, b.max) : null;
    });
  }

  void _apply() {
    final all = ref.read(productListProvider).valueOrNull;
    if (all == null) return;
    final b = homePriceBoundsFromProducts(all);
    final idToName = ref.read(categoryIdToNameProvider).valueOrNull ?? {};
    final idToGender =
        ref.read(categoryIdToGenderProvider).valueOrNull ?? {};
    final chips = ShopCatalog.shopFilterChipsFor(all, idToName);

    ref.read(homeForAudienceProvider.notifier).state = _draftForAudience;

    var catIdx = _draftCategoryIndex;
    if (catIdx > 0 &&
        catIdx < chips.categoryIds.length &&
        !categoryIdMatchesShopFor(
          chips.categoryIds[catIdx],
          _draftForAudience,
          idToGender,
        )) {
      catIdx = 0;
    }
    ref.read(categoryFilterIndexProvider.notifier).state = catIdx;

    final r = _displayRange(b);
    if (isHomePriceRangeFullSpan(r, b)) {
      ref.read(homePriceRangeFilterProvider.notifier).state = null;
    } else {
      ref.read(homePriceRangeFilterProvider.notifier).state = r;
    }

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productListProvider);
    final idToName = ref.watch(categoryIdToNameProvider).valueOrNull ?? {};
    final idToGender =
        ref.watch(categoryIdToGenderProvider).valueOrNull ?? {};

    return Material(
      color: ShopTokens.cardBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ShopTokens.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Expanded(
                child: asyncProducts.when(
                  data: (all) {
                    final chips = ShopCatalog.shopFilterChipsFor(all, idToName);
                    final bounds = homePriceBoundsFromProducts(all);
                    final display = _displayRange(bounds);

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'For',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: ShopTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Who are you shopping for? Category options below update.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: ShopTokens.textSecondary
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ShopForAudience.values.map((aud) {
                              final sel = aud == _draftForAudience;
                              return FilterChip(
                                label: Text(aud.filterLabel),
                                selected: sel,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setState(() {
                                    _draftForAudience = aud;
                                    if (_draftCategoryIndex > 0 &&
                                        _draftCategoryIndex <
                                            chips.categoryIds.length &&
                                        !categoryIdMatchesShopFor(
                                          chips.categoryIds[
                                              _draftCategoryIndex],
                                          _draftForAudience,
                                          idToGender,
                                        )) {
                                      _draftCategoryIndex = 0;
                                    }
                                  });
                                },
                                selectedColor: const Color(0xFFE9E9E9),
                                backgroundColor: ShopTokens.cardBackground,
                                side: BorderSide(
                                  color: sel
                                      ? HomeFilterDrawer._accent
                                          .withValues(alpha: 0.45)
                                      : const Color(0xFFE5E7EB),
                                ),
                                labelStyle: const TextStyle(
                                  color: ShopTokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: ShopTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Department or All. Light chips don't fit your For pick.",
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: ShopTokens.textSecondary
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(chips.labels.length, (i) {
                              final sel = i == _draftCategoryIndex;
                              final catEnabled = i == 0 ||
                                  categoryIdMatchesShopFor(
                                    chips.categoryIds[i],
                                    _draftForAudience,
                                    idToGender,
                                  );
                              return Opacity(
                                opacity: catEnabled ? 1 : 0.38,
                                child: FilterChip(
                                  label: Text(chips.labels[i]),
                                  selected: sel,
                                  showCheckmark: false,
                                  onSelected: catEnabled
                                      ? (_) {
                                          setState(
                                            () => _draftCategoryIndex = i,
                                          );
                                        }
                                      : null,
                                  selectedColor: const Color(0xFFE9E9E9),
                                  backgroundColor: ShopTokens.cardBackground,
                                  side: BorderSide(
                                    color: sel
                                        ? HomeFilterDrawer._accent
                                            .withValues(alpha: 0.45)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                  labelStyle: const TextStyle(
                                    color: ShopTokens.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Price range',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: ShopTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${display.start.toStringAsFixed(0)} – ${display.end.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: ShopTokens.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          RangeSlider(
                            values: display,
                            min: bounds.min,
                            max: bounds.max,
                            activeColor: HomeFilterDrawer._accent,
                            inactiveColor: const Color(0xFFE5E7EB),
                            onChanged: (v) {
                              setState(() => _draftPriceRange = v);
                            },
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                setState(
                                  () => _draftPriceRange =
                                      RangeValues(bounds.min, bounds.max),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: HomeFilterDrawer._accent,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Reset price'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Could not load filters: $e'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _resetDraft,
                      style: TextButton.styleFrom(
                        foregroundColor: ShopTokens.textSecondary,
                      ),
                      child: const Text('Reset all'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: asyncProducts.hasValue ? _apply : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: HomeFilterDrawer._accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
