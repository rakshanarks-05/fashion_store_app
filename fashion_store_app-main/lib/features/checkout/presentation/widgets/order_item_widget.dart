import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../../../cart/presentation/models/cart_resolved_line.dart';
import '../../../cart/presentation/utils/cart_formatters.dart';
import '../theme/checkout_tokens.dart';

/// Single checkout line: circular image, quantity badge, title, price (reference layout).
class OrderItemWidget extends StatelessWidget {
  const OrderItemWidget({
    super.key,
    required this.line,
    required this.subtitle,
  });

  final CartResolvedLine line;
  final String subtitle;

  static const double _imageSize = 56;

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    final name = p?.name ?? 'Product ${line.productId}';
    final imageUrl = p?.imageUrl ?? '';
    final qty = line.cartItem.quantity;
    final lineTotal = p == null
        ? 0.0
        : (p.price * qty).roundToDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _imageSize,
            height: _imageSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: ProductNetworkImage(
                    imageUrl: imageUrl,
                    width: _imageSize,
                    height: _imageSize,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: CheckoutTokens.body,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: CheckoutTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: CheckoutTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatLkr(lineTotal),
            style: const TextStyle(
              fontSize: CheckoutTokens.price,
              fontWeight: FontWeight.w800,
              color: CheckoutTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
