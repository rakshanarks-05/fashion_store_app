import 'package:flutter/material.dart';

import '../theme/profile_ui_tokens.dart';

class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileUiTokens.pageBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ProfileUiTokens.screenHorizontal,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: ProfileUiTokens.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: ProfileUiTokens.textPrimary,
                      ),
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: ProfileUiTokens.textSecondary,
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
