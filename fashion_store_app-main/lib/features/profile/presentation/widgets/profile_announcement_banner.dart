import 'package:flutter/material.dart';

import '../theme/profile_ui_tokens.dart';

class ProfileAnnouncementBanner extends StatelessWidget {
  const ProfileAnnouncementBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ProfileUiTokens.screenHorizontal),
      child: Material(
        color: ProfileUiTokens.bannerFill,
        borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Announcement',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: ProfileUiTokens.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fresh arrivals alert! Check out the newest trends in your favorite fashion categories now.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.35,
                              color: ProfileUiTokens.textSecondary,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: ProfileUiTokens.accentBlue,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onTap,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
}
