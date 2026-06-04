import 'package:flutter/material.dart';

import '../../theme/payment_tokens.dart';

/// Modal overlay: dimmed background + centered “Payment is in progress” card.
class PaymentProcessingOverlay extends StatelessWidget {
  const PaymentProcessingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Material(
              color: PaymentTokens.sectionWhite,
              elevation: 12,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 52, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Payment is in progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: PaymentTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please, wait a few moments',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: PaymentTokens.textPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: PaymentTokens.sectionWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    color: primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showPaymentProcessingDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: PaymentTokens.barrierDim,
    builder: (context) => const PaymentProcessingOverlay(),
  );
}
