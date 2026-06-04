import 'package:flutter/material.dart';

/// Visual tokens aligned with the fashion shop mockups (primary blue, spacing, type scale).
abstract final class ShopTokens {
  static const Color primaryBlue = Color(0xFF0055FF);
  static const Color pageBackground = Color(0xFFF5F6F8);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color searchFill = Color(0xFFEDEDF0);
  static const Color badgeBlue = Color(0xFFE8EEFF);
  static const Color saleBadge = Color(0xFFFF4D6A);
  static const Color filterBadge = Color(0xFFF07D74);

  static const double screenHorizontal = 18;
  static const double sectionGap = 26;
  static const double cardRadius = 14;
  static const double imageRadius = 12;

  static const double titleLarge = 28;
  static const double sectionTitle = 18;
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
