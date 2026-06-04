import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../models/shop_catalog.dart';
import '../theme/shop_tokens.dart';

class MostPopularCard extends StatelessWidget {
  const MostPopularCard({
    super.key,
    required this.item,
    required this.width,
    this.onFavoriteTap,
  });

  final ShopPopularItem item;
  final double width;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: ShopTokens.cardBackground,
        borderRadius: BorderRadius.circular(ShopTokens.imageRadius),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShopTokens.imageRadius),
            boxShadow: ShopTokens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ProductNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Text(
                      item.price.round().toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: ShopTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: onFavoriteTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.favorite_border,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: ShopTokens.textSecondary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
