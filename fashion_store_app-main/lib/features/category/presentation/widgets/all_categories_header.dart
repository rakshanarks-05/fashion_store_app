import 'package:flutter/material.dart';

import '../../../product/presentation/theme/shop_tokens.dart';

/// Title row with close action (full-screen sheet or pushed route).
class AllCategoriesHeader extends StatelessWidget {
  const AllCategoriesHeader({
    super.key,
    this.title = 'All Categories',
    this.onClose,
  });

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShopTokens.screenHorizontal,
        8,
        ShopTokens.screenHorizontal,
        4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    color: ShopTokens.textPrimary,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
          IconButton(
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              foregroundColor: ShopTokens.textPrimary,
            ),
            icon: const Icon(Icons.close, size: 26),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
    );
  }
}
