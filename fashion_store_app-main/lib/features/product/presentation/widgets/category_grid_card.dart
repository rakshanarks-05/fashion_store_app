import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../models/shop_catalog.dart';
import '../theme/shop_tokens.dart';

class CategoryGridCard extends StatelessWidget {
  const CategoryGridCard({super.key, required this.category, this.onTap});

  final ShopCategoryTile category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final thumbs = category.thumbnailUrls;
    return Material(
      color: ShopTokens.cardBackground,
      borderRadius: BorderRadius.circular(ShopTokens.cardRadius),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShopTokens.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShopTokens.cardRadius),
            boxShadow: ShopTokens.cardShadow,
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(ShopTokens.imageRadius),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _QuadThumbnails(urls: thumbs),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: ShopTokens.body + 1,
                        color: ShopTokens.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ShopTokens.badgeBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${category.productCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ShopTokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuadThumbnails extends StatelessWidget {
  const _QuadThumbnails({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: List.generate(4, (i) {
        final url = i < urls.length ? urls[i] : '';
        if (url.isEmpty) {
          return const _NoImageCell();
        }
        return ColoredBox(
          color: ShopTokens.searchFill,
          child: ProductNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            cloudinaryVariant: CloudinaryVariant.thumbnail,
          ),
        );
      }),
    );
  }
}

class _NoImageCell extends StatelessWidget {
  const _NoImageCell();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShopTokens.searchFill,
      child: Center(
        child: Text(
          'No Image',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: ShopTokens.textSecondary.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
