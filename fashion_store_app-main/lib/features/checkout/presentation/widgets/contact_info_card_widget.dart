import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Phone + email card matching the reference layout.
class ContactInfoCardWidget extends StatelessWidget {
  const ContactInfoCardWidget({
    super.key,
    required this.phone,
    required this.email,
    required this.onEdit,
    this.backgroundColor,
    this.boxShadow,
    this.editButtonColor,
  });

  final String phone;
  final String email;
  final VoidCallback onEdit;

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
                  'Contact Information',
                  style: TextStyle(
                    fontSize: CheckoutTokens.sectionTitle,
                    fontWeight: FontWeight.w700,
                    color: CheckoutTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: CheckoutTokens.body,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: CheckoutTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: CheckoutTokens.body,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
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
