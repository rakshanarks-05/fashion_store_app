import 'package:flutter/material.dart';

/// Layout and color tokens for the profile / dashboard screen (design reference).
abstract final class ProfileUiTokens {
  static const Color accentBlue = Color(0xFF1D61FF);
  static const Color pageBackground = Color(0xFFFFFFFF);
  static const Color bannerFill = Color(0xFFF3F4F6);
  static const Color chipFill = Color(0xFFEEF0FF);
  static const Color iconBoxBorder = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color notificationDot = Color(0xFF1D61FF);
  static const Color statusDot = Color(0xFF22C55E);

  static const double screenHorizontal = 18;
  static const double sectionGap = 24;
  static const double cardRadius = 16;
  static const double chipRadius = 20;
  static const double avatarRadius = 22;
  static const double storyCardWidth = 124;
  static const double storyCardHeight = 196;

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}
