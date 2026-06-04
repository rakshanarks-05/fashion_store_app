import 'package:flutter/material.dart';

import '../theme/shop_tokens.dart';

/// Centered empty state when a product list has no matches.
class ProductSearchEmptyState extends StatelessWidget {
  const ProductSearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: ShopTokens.screenHorizontal,
      ),
      child: Center(
        child: Text(
          'No products found',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ShopTokens.textSecondary,
              ),
        ),
      ),
    );
  }
}
