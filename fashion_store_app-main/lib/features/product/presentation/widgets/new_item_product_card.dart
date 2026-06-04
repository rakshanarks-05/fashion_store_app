import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../models/shop_catalog.dart';
import '../theme/shop_tokens.dart';
import 'add_to_cart_button.dart';
import 'price_tag.dart';

class NewItemProductCard extends StatelessWidget {
  const NewItemProductCard({
    super.key,
    required this.product,
    required this.cardWidth,
    required this.onAddToCart,
  });

  final ShopProductItem product;
  final double cardWidth;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(ShopTokens.imageRadius),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ProductNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    width: cardWidth,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: AddToCartButton(onPressed: onAddToCart, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: ShopTokens.body,
              color: ShopTokens.textSecondary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          PriceTag(amount: product.price),
        ],
      ),
    );
  }
}
