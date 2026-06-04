import 'package:flutter/material.dart';

/// Payment flow — aligned with reference mocks (#0055FF primary).
abstract final class PaymentTokens {
  static const Color primaryBlue = Color(0xFF0055FF);
  static const Color pageBackgroundTop = Color(0xFFF5F6F8);
  static const Color sectionWhite = Color(0xFFFFFFFF);
  static const Color shippingCardFill = Color(0xFFF3F4F6);
  static const Color savedCardFill = Color(0xFFEEF2F8);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color discountPillFill = Color(0xFFE8F0FF);
  static const Color payDisabled = Color(0xFFBDBDBD);
  static const Color modalButtonGrey = Color(0xFFE8E8EA);
  static const Color barrierDim = Color(0x66000000);
  static const Color mastercardRed = Color(0xFFEB001B);
  static const Color mastercardOrange = Color(0xFFF79E1B);

  static const double horizontalPadding = 20;
  static const double cardRadius = 14;
  static const double modalRadius = 22;
  static const double addButtonWidth = 52;

  static const double titleSize = 28;
  static const double sectionTitle = 16;
  static const double body = 13;
}
