import 'package:flutter/material.dart';

/// Cart screen layout tokens aligned with the reference mockup.
abstract final class CartTokens {
  static const Color background = Color(0xFFFFFFFF);
  static const Color primaryBlue = Color(0xFF0055FF);
  /// Shop / home accent (coral) — use for quantity steppers and primary actions in themed flows.
  static const Color accent = Color(0xFFF07D74);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color shippingCardFill = Color(0xFFF3F4F6);
  static const Color badgeFill = Color(0xFFE8EEFF);
  static const Color quantityBoxFill = Color(0xFFF3F3F3);
  static const Color checkoutBarFill = Color(0xFFF5F6F8);
  static const Color navBorder = Color(0xFFE5E7EB);

  static const double horizontalPadding = 16;
  static const double cardRadius = 14;
  static const double imageSize = 96;
  static const double imageRadius = 12;

  static const double titleSize = 28;
  static const double sectionTitleSize = 18;
  static const double bodySize = 13;
  static const double priceSize = 15;
  static const double shippingTitleSize = 15;
  static const double shippingBodySize = 13;
}
