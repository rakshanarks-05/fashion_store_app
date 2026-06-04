import 'package:flutter/material.dart';

import '../theme/shop_tokens.dart';

/// Five-icon bar matching the reference (Home indicator bar on active item).
class ShopBottomNavigationBar extends StatelessWidget {
  const ShopBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.indicatorColor,
    this.showCartNotificationDot = false,
    this.cartNotificationDotColor,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// When null, selected icons use [ShopTokens.textPrimary].
  final Color? selectedIconColor;

  /// When null, unselected icons use [ShopTokens.textSecondary].
  final Color? unselectedIconColor;

  /// When null, the bottom indicator uses [selectedIconColor] or [ShopTokens.textPrimary].
  final Color? indicatorColor;

  /// When true, shows a small dot on the cart (bag) tab (index 3).
  final bool showCartNotificationDot;

  /// Dot color; defaults to primary blue when null.
  final Color? cartNotificationDotColor;

  static const _icons = [
    Icons.home_outlined,
    Icons.favorite_border,
    Icons.receipt_long_outlined,
    Icons.shopping_bag_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final selectedColor = selectedIconColor ?? ShopTokens.textPrimary;
    final unselectedColor = unselectedIconColor ?? ShopTokens.textSecondary;
    final barColor = indicatorColor ?? selectedColor;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ShopTokens.cardBackground,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (i) {
              final selected = i == currentIndex;
              return InkWell(
                onTap: () => onTap(i),
                child: SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            _icons[i],
                            color: selected ? selectedColor : unselectedColor,
                            size: 26,
                          ),
                          if (showCartNotificationDot && i == 3)
                            Positioned(
                              right: -2,
                              top: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: cartNotificationDotColor ??
                                      const Color(0xFF0055FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ShopTokens.cardBackground,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: selected ? 22 : 0,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Three-tab bar (Home / Cart / Profile) used on Home, Cart, Profile, and related flows.
///
/// [currentIndex] matches [ShopBottomNavigationBar]: `0` home, `3` cart, `4` profile.
/// Indices `1`–`2` (wishlist / orders) show **no** tab highlighted.
/// [onTap] receives the same indices (`0`, `3`, `4`) when those tabs are pressed.
class ShopHomeBottomNavigationBar extends StatelessWidget {
  const ShopHomeBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showCartNotificationDot = false,
    this.cartNotificationDotColor,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showCartNotificationDot;
  final Color? cartNotificationDotColor;

  static const Color _accent = Color(0xFFF07D74);
  static const Color _muted = Color(0xFFB7B7B7);

  int? _selectedVisualIndex() {
    switch (currentIndex) {
      case 0:
        return 0;
      case 3:
        return 1;
      case 4:
        return 2;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVisual = _selectedVisualIndex();
    final dotColor = cartNotificationDotColor ?? _accent;

    Widget item({
      required int visualIndex,
      required IconData icon,
      required String label,
      required int mappedIndex,
      bool showDot = false,
    }) {
      final isSelected = selectedVisual == visualIndex;
      final color = isSelected ? _accent : _muted;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(mappedIndex),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: SizedBox(
            width: 86,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: color, size: 22),
                    if (showDot)
                      Positioned(
                        right: -4,
                        top: -6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              item(
                visualIndex: 0,
                icon: Icons.home_outlined,
                label: 'Home',
                mappedIndex: 0,
              ),
              item(
                visualIndex: 1,
                icon: Icons.shopping_cart_outlined,
                label: 'Cart',
                mappedIndex: 3,
                showDot: showCartNotificationDot,
              ),
              item(
                visualIndex: 2,
                icon: Icons.person_outline,
                label: 'Profile',
                mappedIndex: 4,
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
