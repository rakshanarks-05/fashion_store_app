import 'package:flutter/material.dart';

import '../../../product/presentation/theme/shop_tokens.dart';
import '../models/all_categories_models.dart';

/// White card: thumbnail + title + chevron; expands to sub-categories and/or [expandedBody].
class ExpandableCategoryCard extends StatelessWidget {
  const ExpandableCategoryCard({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggleExpand,
    this.expandedBody,
    this.onSubcategoryTap,
    this.fadeAnimation,
  });

  final CatalogCategoryGroup group;
  final bool expanded;
  /// Toggles expansion (header row and chevron).
  final VoidCallback onToggleExpand;
  /// Shown when [expanded] (e.g. inline product list). Omit when collapsed to avoid extra work.
  final Widget? expandedBody;
  final void Function(String name)? onSubcategoryTap;
  final Animation<double>? fadeAnimation;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: ShopTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ShopTokens.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onToggleExpand,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Row(
                            children: [
                              _CategoryThumb(url: group.imageUrl),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: ShopTokens.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onToggleExpand,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: ShopTokens.primaryBlue,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (group.subcategories.isNotEmpty) ...[
                              _SubcategoryPillGrid(
                                labels: group.subcategories,
                                onTap: onSubcategoryTap,
                              ),
                              if (expandedBody != null)
                                const SizedBox(height: 12),
                            ],
                            ?expandedBody,
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );

    if (fadeAnimation != null) {
      return FadeTransition(
        opacity: fadeAnimation!,
        child: card,
      );
    }
    return card;
  }
}

class _CategoryThumb extends StatelessWidget {
  const _CategoryThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: ShopTokens.searchFill,
            child: Icon(Icons.image_outlined, color: Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryPillGrid extends StatelessWidget {
  const _SubcategoryPillGrid({
    required this.labels,
    this.onTap,
  });

  final List<String> labels;
  final void Function(String name)? onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 40,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: labels.length,
      itemBuilder: (context, i) {
        final label = labels[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap != null ? () => onTap!(label) : null,
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: ShopTokens.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
