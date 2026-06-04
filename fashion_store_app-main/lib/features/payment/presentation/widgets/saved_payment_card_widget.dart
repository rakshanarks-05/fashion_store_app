import 'package:flutter/material.dart';

import '../theme/payment_tokens.dart';

/// Mastercard-style row + vertical “+” add button (reference layout).
class SavedPaymentCardWidget extends StatelessWidget {
  const SavedPaymentCardWidget({
    super.key,
    required this.maskedNumberLine,
    required this.holderName,
    required this.expiryMmYy,
    required this.onSettings,
    required this.onAddTap,
  });

  final String maskedNumberLine;
  final String holderName;
  final String expiryMmYy;
  final VoidCallback onSettings;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              decoration: BoxDecoration(
                color: PaymentTokens.savedCardFill,
                borderRadius: BorderRadius.circular(PaymentTokens.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _MastercardLogo(),
                      const Spacer(),
                      Material(
                        color: PaymentTokens.discountPillFill,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onSettings,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.settings_outlined,
                              size: 18,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    maskedNumberLine,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      color: PaymentTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          holderName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: PaymentTokens.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        expiryMmYy,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: PaymentTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onAddTap,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: PaymentTokens.addButtonWidth,
                child: Center(
                  child: Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MastercardLogo extends StatelessWidget {
  const _MastercardLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: PaymentTokens.mastercardRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 14,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: PaymentTokens.mastercardOrange.withValues(alpha: 0.95),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
