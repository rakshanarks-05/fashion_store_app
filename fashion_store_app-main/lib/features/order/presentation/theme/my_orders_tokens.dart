import 'package:flutter/material.dart';

/// Visual tokens for the My Orders mockup (pixel-aligned with design reference).
abstract final class MyOrdersTokens {
  static const Color pageBackground = Color(0xFFF8F8F8);
  static const Color primaryBlue = Color(0xFF0055FF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
  static const Color iconCircleFill = Color(0xFFE6EEFF);
  static const Color itemCountPill = Color(0xFFEEEEEE);
  static const Color cardShadow = Color(0x14000000);

  static const double screenHorizontal = 20;
  static const double cardRadius = 16;
  static const double imageRadius = 12;
  static const double cardInnerPadding = 12;
  static const double cardGap = 16;
  static const double titleLarge = 24;
  static const double subtitle = 14;
  static const double cardTitle = 16;
  static const double cardMeta = 13;
  static const double statusLine = 15;
  static const double itemCount = 12;

  static List<BoxShadow> cardShadows = [
    BoxShadow(
      color: cardShadow,
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
}
