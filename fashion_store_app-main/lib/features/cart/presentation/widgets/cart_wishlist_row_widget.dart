import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../../../product/domain/entities/product.dart';
import '../theme/cart_tokens.dart';
import '../utils/cart_formatters.dart';

class CartWishlistRowWidget extends StatelessWidget {
  const CartWishlistRowWidget({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.chips,
  });

  final Product product;
  final VoidCallback onAddToCart;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CartTokens.background,
        borderRadius: BorderRadius.circular(CartTokens.cardRadius),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CartTokens.imageRadius),
            child: ProductNetworkImage(
              imageUrl: product.imageUrl,
              width: CartTokens.imageSize,
              height: CartTokens.imageSize,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: CartTokens.bodySize,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: CartTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CartTokens.shippingCardFill,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: CartTokens.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        formatLkr(product.price),
                        style: const TextStyle(
                          fontSize: CartTokens.priceSize,
                          fontWeight: FontWeight.w800,
                          color: CartTokens.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: CartTokens.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: onAddToCart,
                          borderRadius: BorderRadius.circular(10),
                          child: const SizedBox(
                            width: 44,
                            height: 36,
                            child: Icon(
                              Icons.add_shopping_cart_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
