import 'package:flutter/material.dart';

/// Compact cart affordance for product surfaces (icon-first to match airy cards).
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({
    super.key,
    required this.onPressed,
    this.size = 36,
  });

  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.add_shopping_cart_outlined,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
