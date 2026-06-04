import 'package:flutter/material.dart';

import '../theme/profile_ui_tokens.dart';

/// Horizontal row of circular thumbnails (placeholder colors if no URLs).
class ProfileRecentlyViewedRow extends StatelessWidget {
  const ProfileRecentlyViewedRow({
    super.key,
    this.imageUrls = const [],
    this.onItemTap,
  });

  final List<String> imageUrls;
  final ValueChanged<int>? onItemTap;

  static const List<Color> _fallbackColors = [
    Color(0xFFE8DDD5),
    Color(0xFFD4E4F0),
    Color(0xFFE5E0F5),
    Color(0xFFF0E0E8),
    Color(0xFFE0EBE4),
  ];

  @override
  Widget build(BuildContext context) {
    const count = 5;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ProfileUiTokens.screenHorizontal),
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          return _CircleThumb(
            index: i,
            imageUrl: i < imageUrls.length ? imageUrls[i] : null,
            fallbackColor: _fallbackColors[i % _fallbackColors.length],
            onTap: onItemTap != null ? () => onItemTap!(i) : null,
          );
        },
      ),
    );
  }
}

class _CircleThumb extends StatelessWidget {
  const _CircleThumb({
    required this.index,
    this.imageUrl,
    required this.fallbackColor,
    this.onTap,
  });

  final int index;
  final String? imageUrl;
  final Color fallbackColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: ProfileUiTokens.subtleShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholderIcon(),
            )
          : _placeholderIcon(),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: child,
      ),
    );
  }

  Widget _placeholderIcon() {
    return Icon(
      Icons.checkroom_outlined,
      color: ProfileUiTokens.textSecondary.withValues(alpha: 0.45),
      size: 28,
    );
  }
}
