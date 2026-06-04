import 'package:flutter/material.dart';

import '../theme/shop_tokens.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.icon,
  });

  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShopTokens.screenHorizontal),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: ShopTokens.sectionTitle,
                  color: ShopTokens.textPrimary,
                ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 6),
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ],
          const Spacer(),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class SeeAllTrailing extends StatelessWidget {
  const SeeAllTrailing({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'See All',
            style: TextStyle(
              color: ShopTokens.textSecondary,
              fontSize: ShopTokens.body,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
