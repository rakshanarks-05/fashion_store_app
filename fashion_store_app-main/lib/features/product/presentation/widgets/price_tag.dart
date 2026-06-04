import 'package:flutter/material.dart';

import '../../../../core/utils/currency_format.dart';
import '../theme/shop_tokens.dart';

/// Formatted currency line used under product titles (global currency format).
class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.amount,
    this.style,
  });

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formatted = CurrencyFormat.format(amount);
    final base = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: ShopTokens.textPrimary,
          fontSize: ShopTokens.price,
        );
    return Text(
      formatted,
      style: style ?? base,
    );
  }
}
