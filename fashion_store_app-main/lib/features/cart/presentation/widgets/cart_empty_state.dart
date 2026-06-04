import 'package:flutter/material.dart';

import '../theme/cart_tokens.dart';

class CartEmptyState extends StatelessWidget {
  const CartEmptyState({
    super.key,
    required this.onContinueShopping,
  });

  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CartTokens.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: CartTokens.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: CartTokens.sectionTitleSize,
                fontWeight: FontWeight.w800,
                color: CartTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from the shop to see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: CartTokens.bodySize,
                color: CartTokens.textSecondary.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onContinueShopping,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue shopping',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
