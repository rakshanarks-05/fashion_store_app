import 'package:flutter/material.dart';

import '../../../../core/widgets/product_network_image.dart';
import '../models/cart_resolved_line.dart';
import '../theme/cart_tokens.dart';
import '../utils/cart_formatters.dart';
import 'cart_quantity_selector.dart';

class CartItemWidget extends StatelessWidget {
  const CartItemWidget({
    super.key,
    required this.line,
    required this.subtitle,
    required this.selected,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
    this.onEdit,
  });

  final CartResolvedLine line;
  final String subtitle;
  final bool selected;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    final name = p?.name ?? 'Product ${line.productId}';
    final imageUrl = p?.imageUrl ?? '';
    final price = p?.price ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CartTokens.background,
        borderRadius: BorderRadius.circular(CartTokens.cardRadius),
        border: Border.all(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: selected ? 1.5 : 0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: CartTokens.imageSize,
            height: CartTokens.imageSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(CartTokens.imageRadius),
                  child: ProductNetworkImage(
                    imageUrl: imageUrl,
                    width: CartTokens.imageSize,
                    height: CartTokens.imageSize,
                    fit: BoxFit.cover,
                    cloudinaryVariant: CloudinaryVariant.thumbnail,
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                    name,
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
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: CartTokens.bodySize,
                      fontWeight: FontWeight.w400,
                      color: CartTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatLkr(price),
                        style: const TextStyle(
                          fontSize: CartTokens.priceSize,
                          fontWeight: FontWeight.w800,
                          color: CartTokens.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (onEdit != null) ...[
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      CartQuantitySelector(
                        quantity: line.cartItem.quantity,
                        onDecrement: onDecrement,
                        onIncrement: onIncrement,
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
