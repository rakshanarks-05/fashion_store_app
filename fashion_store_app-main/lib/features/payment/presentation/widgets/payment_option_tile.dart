import 'package:flutter/material.dart';

import '../theme/payment_tokens.dart';

/// Selectable row for Credit/Debit vs Cash on Delivery (radio-style).
class PaymentOptionTile extends StatelessWidget {
  const PaymentOptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PaymentTokens.cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? PaymentTokens.discountPillFill.withValues(alpha: 0.65)
                : PaymentTokens.sectionWhite,
            borderRadius: BorderRadius.circular(PaymentTokens.cardRadius),
            border: Border.all(
              color: selected ? primary : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
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
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: PaymentTokens.body + 1,
                    fontWeight: FontWeight.w600,
                    color: PaymentTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
