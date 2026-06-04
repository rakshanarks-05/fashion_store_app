import 'package:flutter/material.dart';

import '../../features/product/presentation/theme/shop_tokens.dart';

/// Global app theme aligned with the Home (shop) page design.
abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      // Brand primary used for main actions across the app.
      primary: ShopTokens.filterBadge,
      onPrimary: Colors.white,
      secondary: ShopTokens.badgeBlue,
      onSecondary: ShopTokens.textPrimary,
      tertiary: ShopTokens.saleBadge,
      onTertiary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: ShopTokens.cardBackground,
      onSurface: ShopTokens.textPrimary,
      surfaceContainerHighest: ShopTokens.searchFill,
      onSurfaceVariant: ShopTokens.textSecondary,
      outline: Color(0xFFE5E7EB),
      outlineVariant: Color(0xFFF1F5F9),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ShopTokens.textPrimary,
      onInverseSurface: Colors.white,
      inversePrimary: ShopTokens.filterBadge,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ShopTokens.pageBackground,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        height: 1.1,
        color: ShopTokens.textPrimary,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: ShopTokens.sectionTitle,
        color: ShopTokens.textPrimary,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: ShopTokens.body,
        color: ShopTokens.textPrimary,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        color: ShopTokens.textSecondary,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    const radius = Radius.circular(ShopTokens.cardRadius);
    final rounded = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(radius),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ShopTokens.pageBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: ShopTokens.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: ShopTokens.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: ShopTokens.cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded,
        shadowColor: Colors.black.withValues(alpha: 0.06),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShopTokens.searchFill,
        hintStyle: textTheme.bodyMedium?.copyWith(color: ShopTokens.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radius),
          borderSide: const BorderSide(color: ShopTokens.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(radius),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ShopTokens.filterBadge,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: rounded,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShopTokens.filterBadge,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: rounded,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ShopTokens.textSecondary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.1,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ShopTokens.textPrimary,
        textColor: ShopTokens.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: rounded,
      ),
      iconTheme: const IconThemeData(color: ShopTokens.textPrimary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ShopTokens.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ShopTokens.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: rounded,
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}

