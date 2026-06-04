import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_for_audience.dart';
import '../providers/home_for_audience_provider.dart';
import '../providers/product_providers.dart';
import '../providers/product_shop_providers.dart';
import '../theme/shop_tokens.dart';

/// Horizontal category / filter chips (reusable; driven by catalog labels).
///
/// [categoryIds] must align with [labels] (index 0 = **All** → `null`).
class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({
    super.key,
    required this.labels,
    required this.categoryIds,
  }) : assert(labels.length == categoryIds.length);

  final List<String> labels;
  final List<String?> categoryIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(categoryFilterIndexProvider);
    final forAudience = ref.watch(homeForAudienceProvider);
    final idToGender =
        ref.watch(categoryIdToGenderProvider).valueOrNull ?? {};

    ref.listen<ShopForAudience>(homeForAudienceProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sel = ref.read(categoryFilterIndexProvider);
        if (sel <= 0 || sel >= categoryIds.length) return;
        final g =
            ref.read(categoryIdToGenderProvider).valueOrNull ?? {};
        if (!categoryIdMatchesShopFor(categoryIds[sel], next, g)) {
          ref.read(categoryFilterIndexProvider.notifier).state = 0;
        }
      });
    });

    const selectedBg = Color(0xFFE9E9E9);
    const unselectedBg = Color(0xFFFFFFFF);
    const unselectedBorder = Color(0xFFE5E7EB);

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ShopTokens.screenHorizontal),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = index == selected;
          final enabled = index == 0 ||
              categoryIdMatchesShopFor(
                categoryIds[index],
                forAudience,
                idToGender,
              );
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled
                ? () => ref.read(categoryFilterIndexProvider.notifier).state = index
                : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.38,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : unselectedBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? selectedBg : unselectedBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      color: ShopTokens.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
