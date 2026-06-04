import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../models/shop_catalog.dart';
import '../theme/shop_tokens.dart';
import 'add_to_cart_button.dart';
import 'price_tag.dart';

/// List row styled like category cards: white surface, 48px thumb, title, price, cart.
class ProductListRowCard extends StatelessWidget {
  const ProductListRowCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final ShopProductItem product;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShopTokens.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ShopTokens.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: product.imageUrl.trim().isEmpty
                      ? ColoredBox(
                          color: ShopTokens.searchFill,
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade500,
                          ),
                        )
                      : ProductNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          cloudinaryVariant: CloudinaryVariant.thumbnail,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ShopTokens.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PriceTag(amount: product.price),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AddToCartButton(onPressed: onAddToCart, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}
