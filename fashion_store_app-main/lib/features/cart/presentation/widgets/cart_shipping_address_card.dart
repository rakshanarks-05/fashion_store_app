import 'package:flutter/material.dart';

import '../theme/cart_tokens.dart';

class CartShippingAddressCard extends StatelessWidget {
  const CartShippingAddressCard({
    super.key,
    required this.address,
    required this.onEdit,
  });

  final String address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: CartTokens.shippingCardFill,
        borderRadius: BorderRadius.circular(CartTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: CartTokens.shippingTitleSize,
                    fontWeight: FontWeight.w700,
                    color: CartTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: CartTokens.shippingBodySize,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: CartTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onEdit,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
