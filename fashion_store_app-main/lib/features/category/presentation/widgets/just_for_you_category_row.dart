import 'package:flutter/material.dart';

import '../../../product/presentation/theme/shop_tokens.dart';

/// Bottom row: "Just for You" + star + circular blue arrow button.
class JustForYouCategoryRow extends StatelessWidget {
  const JustForYouCategoryRow({
    super.key,
    this.onTap,
    this.fadeAnimation,
  });

  final VoidCallback? onTap;
  final Animation<double>? fadeAnimation;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: ShopTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ShopTokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                const Text(
                  'Just for You',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ShopTokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.star_rounded, color: ShopTokens.primaryBlue, size: 22),
                const Spacer(),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: ShopTokens.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (fadeAnimation != null) {
      return FadeTransition(opacity: fadeAnimation!, child: card);
    }
    return card;
  }
}
