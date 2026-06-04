import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// White card with title, recipient name, address lines, and circular edit control.
class AddressCardWidget extends StatelessWidget {
  const AddressCardWidget({
    super.key,
    required this.fullName,
    required this.address,
    required this.onEdit,
    this.backgroundColor,
    this.boxShadow,
    this.editButtonColor,
  });

  final String fullName;
  final String address;
  final VoidCallback onEdit;

  /// When null, uses [CheckoutTokens.cardSurface] / [CheckoutTokens.cardShadow].
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Color? editButtonColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: backgroundColor ?? CheckoutTokens.cardSurface,
        borderRadius: BorderRadius.circular(CheckoutTokens.cardRadius),
        boxShadow: boxShadow ?? CheckoutTokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontSize: CheckoutTokens.sectionTitle,
                    fontWeight: FontWeight.w700,
                    color: CheckoutTokens.textPrimary,
                  ),
                ),
                if (fullName.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: CheckoutTokens.body,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: CheckoutTokens.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: CheckoutTokens.body,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: CheckoutTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: editButtonColor ?? Theme.of(context).colorScheme.primary,
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
    );
  }
}
