import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product/presentation/theme/shop_tokens.dart';
import '../models/all_categories_models.dart';
import '../providers/all_categories_providers.dart';

/// Segmented control: All · Female · Male
class GenderTabBar extends ConsumerWidget {
  const GenderTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(genderTabProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShopTokens.screenHorizontal,
        8,
        ShopTokens.screenHorizontal,
        8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 8.0;
          final w = (constraints.maxWidth - gap * 2) / 3;
          return Row(
            children: [
              for (final tab in GenderTab.values) ...[
                if (tab != GenderTab.values.first) SizedBox(width: gap),
                SizedBox(
                  width: w,
                  child: _GenderChip(
                    label: tab.label,
                    selected: selected == tab,
                    onTap: () => ref.read(genderTabProvider.notifier).state = tab,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : const Color(0xFFECEEF1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? ShopTokens.primaryBlue : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: selected ? ShopTokens.primaryBlue : ShopTokens.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
