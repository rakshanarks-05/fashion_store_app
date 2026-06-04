import 'package:flutter/material.dart';

import '../providers/checkout_providers.dart';
import '../theme/checkout_tokens.dart';

/// Standard vs Express rows with radio selection and ETA footer.
class ShippingOptionsWidget extends StatelessWidget {
  const ShippingOptionsWidget({
    super.key,
    required this.option,
    required this.onChanged,
    required this.etaLine,
  });

  final CheckoutShippingOption option;
  final ValueChanged<CheckoutShippingOption> onChanged;
  final String etaLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shipping Options',
          style: TextStyle(
            fontSize: CheckoutTokens.sectionTitle,
            fontWeight: FontWeight.w700,
            color: CheckoutTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _OptionRow(
          selected: option == CheckoutShippingOption.standard,
          title: 'Standard',
          pillText: '5-7 days',
          trailing: 'FREE',
          trailingIsAccent: true,
          background: option == CheckoutShippingOption.standard
              ? CheckoutTokens.selectedShippingFill
              : CheckoutTokens.cardSurface,
          onTap: () => onChanged(CheckoutShippingOption.standard),
          useCheckRadio: option == CheckoutShippingOption.standard,
        ),
        const SizedBox(height: 10),
        _OptionRow(
          selected: option == CheckoutShippingOption.express,
          title: 'Express',
          pillText: '1-2 days',
          trailing: 'Rs. 500',
          trailingIsAccent: false,
          background: option == CheckoutShippingOption.express
              ? CheckoutTokens.selectedShippingFill
              : CheckoutTokens.cardSurface,
          onTap: () => onChanged(CheckoutShippingOption.express),
          useCheckRadio: option == CheckoutShippingOption.express,
        ),
        const SizedBox(height: 10),
        Text(
          etaLine,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: CheckoutTokens.textSecondary.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.selected,
    required this.title,
    required this.pillText,
    required this.trailing,
    required this.trailingIsAccent,
    required this.background,
    required this.onTap,
    required this.useCheckRadio,
  });

  final bool selected;
  final String title;
  final String pillText;
  final String trailing;
  final bool trailingIsAccent;
  final Color background;
  final VoidCallback onTap;
  final bool useCheckRadio;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CheckoutTokens.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(CheckoutTokens.cardRadius),
            boxShadow: CheckoutTokens.cardShadow,
          ),
          child: Row(
            children: [
              _RadioGlyph(selected: selected, filled: useCheckRadio),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: CheckoutTokens.body,
                  fontWeight: FontWeight.w600,
                  color: CheckoutTokens.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CheckoutTokens.pillBackground,
                  borderRadius: BorderRadius.circular(CheckoutTokens.pillRadius),
                ),
                child: Text(
                  pillText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                trailing,
                style: TextStyle(
                  fontSize: CheckoutTokens.price,
                  fontWeight: FontWeight.w700,
                  color: trailingIsAccent
                      ? primary
                      : CheckoutTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioGlyph extends StatelessWidget {
  const _RadioGlyph({required this.selected, required this.filled});

  final bool selected;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled && selected) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 14,
          color: Colors.white,
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFCCCCCC),
          width: 2,
        ),
        color: Colors.transparent,
      ),
    );
  }
}
