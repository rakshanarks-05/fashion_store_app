import 'package:flutter/material.dart';

import '../theme/cart_tokens.dart';

/// Compact − / + stepper with quantity (matches cart row UI).
class CartQuantitySelector extends StatelessWidget {
  const CartQuantitySelector({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(
          icon: Icons.remove,
          onTap: onDecrement,
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CartTokens.quantityBoxFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CartTokens.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _QtyButton(
          icon: Icons.add,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CartTokens.accent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
