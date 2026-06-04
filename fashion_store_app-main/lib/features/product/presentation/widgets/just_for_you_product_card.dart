import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../models/shop_catalog.dart';
import '../theme/shop_tokens.dart';
import 'price_tag.dart';

/// Two-column grid tile: square image, title (2 lines), price, optional cart control.
class JustForYouProductCard extends StatelessWidget {
  const JustForYouProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final ShopProductItem product;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFF3F3F3);
    const actionBg = Color(0xFFEAEAEA);
    const priceColor = Color(0xFFF07D74);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProductNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ShopTokens.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: PriceTag(
                  amount: product.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: priceColor,
                    height: 1.1,
                  ),
                ),
              ),
              InkWell(
                onTap: onAddToCart,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: actionBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 14,
                    color: ShopTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
