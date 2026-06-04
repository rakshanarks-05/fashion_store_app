import 'package:flutter/material.dart';

/// Visual tokens aligned with the payment / checkout reference mockup.
abstract final class CheckoutTokens {
  static const Color background = Color(0xFFF7F8FA);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color primaryBlue = Color(0xFF1E6BFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color payButton = Color(0xFF1A1A1A);
  static const Color pillBackground = Color(0xFFE8F0FF);
  static const Color selectedShippingFill = Color(0xFFE8F0FF);
  static const Color badgeFill = Color(0xFFE0E8F5);

  static const double horizontalPadding = 20;
  static const double sectionGap = 24;
  static const double cardRadius = 14;
  static const double pillRadius = 8;
  static const double buttonRadius = 12;

  static const double screenTitle = 28;
  static const double sectionTitle = 16;
  static const double body = 13;
  static const double price = 15;

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
