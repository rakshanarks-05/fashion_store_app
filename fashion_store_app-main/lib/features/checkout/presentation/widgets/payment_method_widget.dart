import 'package:flutter/material.dart';

import '../providers/checkout_providers.dart';
import '../theme/checkout_tokens.dart';

/// Header row, selected method chip (reference), and optional inline radios via [compact].
class PaymentMethodWidget extends StatelessWidget {
  const PaymentMethodWidget({
    super.key,
    required this.method,
    required this.onEdit,
    this.onSelect,
    this.showInlineOptions = false,
  });

  final CheckoutPaymentMethod method;
  final VoidCallback onEdit;
  final ValueChanged<CheckoutPaymentMethod>? onSelect;

  /// When true, shows Card / COD rows; when false, only chip + edit (compact mockup).
  final bool showInlineOptions;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final label = switch (method) {
      CheckoutPaymentMethod.card => 'Card',
      CheckoutPaymentMethod.cashOnDelivery => 'Cash on Delivery',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: CheckoutTokens.sectionTitle,
                  fontWeight: FontWeight.w700,
                  color: CheckoutTokens.textPrimary,
                ),
              ),
            ),
            Material(
              color: primary,
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
        if (showInlineOptions) ...[
          const SizedBox(height: 12),
          ...CheckoutPaymentMethod.values.map((m) {
            final selected = m == method;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect?.call(m),
                  borderRadius:
                      BorderRadius.circular(CheckoutTokens.cardRadius),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? CheckoutTokens.selectedShippingFill
                          : CheckoutTokens.cardSurface,
                      borderRadius:
                          BorderRadius.circular(CheckoutTokens.cardRadius),
                      boxShadow: CheckoutTokens.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 22,
                          color: selected
                              ? primary
                              : const Color(0xFFBBBBBB),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          m == CheckoutPaymentMethod.card
                              ? 'Card Payment'
                              : 'Cash on Delivery',
                          style: const TextStyle(
                            fontSize: CheckoutTokens.body,
                            fontWeight: FontWeight.w600,
                            color: CheckoutTokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
        SizedBox(height: showInlineOptions ? 4 : 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CheckoutTokens.pillBackground,
              borderRadius: BorderRadius.circular(CheckoutTokens.pillRadius),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
