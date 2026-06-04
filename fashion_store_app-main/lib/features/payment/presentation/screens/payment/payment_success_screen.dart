import 'package:flutter/material.dart';

import '../../theme/payment_tokens.dart';

/// Success modal: overlapping blue check, “Done!”, body copy, Track My Order.
class PaymentSuccessOverlay extends StatelessWidget {
  const PaymentSuccessOverlay({
    super.key,
    required this.onTrackOrder,
    this.orderId,
    this.amountLabel,
  });

  final VoidCallback onTrackOrder;
  final String? orderId;
  final String? amountLabel;

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
            padding: const EdgeInsets.only(top: 36),
            child: Material(
              color: PaymentTokens.sectionWhite,
              elevation: 14,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(PaymentTokens.modalRadius),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Done!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: PaymentTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You card has been successfully charged',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: PaymentTokens.textSecondary,
                      ),
                    ),
                    if (orderId != null && orderId!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Order ID: $orderId',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PaymentTokens.textPrimary,
                        ),
                      ),
                    ],
                    if (amountLabel != null && amountLabel!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Amount paid: $amountLabel',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: PaymentTokens.textPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: PaymentTokens.modalButtonGrey,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: onTrackOrder,
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Track My Order',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: PaymentTokens.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showPaymentSuccessDialog(
  BuildContext context, {
  required VoidCallback onTrackOrder,
  String? orderId,
  String? amountLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: PaymentTokens.barrierDim,
    builder: (context) => PaymentSuccessOverlay(
      onTrackOrder: onTrackOrder,
      orderId: orderId,
      amountLabel: amountLabel,
    ),
  );
}
