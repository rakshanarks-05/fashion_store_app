import 'package:flutter/material.dart';

import '../theme/profile_ui_tokens.dart';

class ProfileStoryItem {
  const ProfileStoryItem({
    this.imageUrl,
    this.isLive = false,
  });

  final String? imageUrl;
  final bool isLive;
}

/// Horizontal story-style cards with play affordance.
class ProfileStoriesRow extends StatelessWidget {
  const ProfileStoriesRow({
    super.key,
    this.items = const [],
    this.onStoryTap,
  });

  final List<ProfileStoryItem> items;
  final ValueChanged<int>? onStoryTap;

  @override
  Widget build(BuildContext context) {
    final list = items.isEmpty ? List.generate(4, (_) => const ProfileStoryItem()) : items;
    return SizedBox(
      height: ProfileUiTokens.storyCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ProfileUiTokens.screenHorizontal),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = list[i];
          return _StoryCard(
            item: item,
            onTap: onStoryTap != null ? () => onStoryTap!(i) : null,
          );
        },
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.item, this.onTap});

  final ProfileStoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
        child: Ink(
          width: ProfileUiTokens.storyCardWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
            color: ProfileUiTokens.bannerFill,
            boxShadow: ProfileUiTokens.subtleShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _placeholder(),
                  )
                else
                  _placeholder(),
                Container(
                  color: Colors.black.withValues(alpha: 0.12),
                ),
                if (item.isLive)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ProfileUiTokens.statusDot,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                      color: ProfileUiTokens.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFD1D5DB),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.white70),
      ),
    );
  }
}
