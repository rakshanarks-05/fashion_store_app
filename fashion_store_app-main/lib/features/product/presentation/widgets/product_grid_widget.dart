import 'package:flutter/material.dart';

import '../models/shop_catalog.dart';
import 'just_for_you_product_card.dart';

/// Responsive 2–3 column wrap of [JustForYouProductCard] tiles.
class ProductGridWidget extends StatelessWidget {
  const ProductGridWidget({
    super.key,
    required this.items,
    required this.onAddToCart,
  });

  final List<ShopProductItem> items;
  final Future<void> Function(ShopProductItem product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = w > 600 ? 3 : 2;
        const spacing = 14.0;
        final tileW = (w - spacing * (crossAxisCount - 1)) / crossAxisCount;
        return Wrap(
          spacing: spacing,
          runSpacing: 20,
          children: [
            for (final p in items)
              SizedBox(
                width: tileW,
                child: JustForYouProductCard(
                  product: p,
                  onAddToCart: () => onAddToCart(p),
                ),
              ),
          ],
        );
      },
    );
  }
}
