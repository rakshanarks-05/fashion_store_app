import 'package:flutter/material.dart';

import '../../../cart/presentation/utils/cart_formatters.dart';
import '../theme/checkout_tokens.dart';

/// Subtotal, delivery, discount, and grand total (scrollable section).
class PriceSummaryWidget extends StatelessWidget {
  const PriceSummaryWidget({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    this.fivePercentDiscount = 0,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double discount;
  /// Optional promo line (same rule as payment screen: 5% of subtotal).
  final double fivePercentDiscount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CheckoutTokens.cardSurface,
        borderRadius: BorderRadius.circular(CheckoutTokens.cardRadius),
        boxShadow: CheckoutTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Price Details',
            style: TextStyle(
              fontSize: CheckoutTokens.sectionTitle,
              fontWeight: FontWeight.w700,
              color: CheckoutTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _row(context, 'Subtotal', formatLkr(subtotal)),
          const SizedBox(height: 10),
          _row(
            context,
            'Delivery Fee',
            deliveryFee <= 0 ? 'FREE' : formatLkr(deliveryFee),
            valueAccent: deliveryFee <= 0,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _row(context, 'Discount', '- ${formatLkr(discount)}', isDiscount: true),
          ],
          if (fivePercentDiscount > 0) ...[
            const SizedBox(height: 10),
            _row(
              context,
              '5% discount',
              '- ${formatLkr(fivePercentDiscount)}',
              isDiscount: true,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _row(
            context,
            'TOTAL',
            formatLkr(total),
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    bool isDiscount = false,
    bool valueAccent = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 15 : CheckoutTokens.body,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              color: CheckoutTokens.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 16 : CheckoutTokens.body,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: isDiscount
                ? const Color(0xFF16A34A)
                : valueAccent
                    ? Theme.of(context).colorScheme.primary
                    : CheckoutTokens.textPrimary,
          ),
        ),
      ],
    );
  }
}
