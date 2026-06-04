import 'package:flutter/material.dart';

import '../theme/profile_ui_tokens.dart';

/// Top dashboard header: avatar, primary action, utility icons, greeting, and edit entry.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    this.subtitle,
    this.photo,
    this.avatarUploading = false,
    this.showMenuButton = false,
    this.onMenuTap,
    this.onMyActivityTap,
    this.onWalletTap,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.onEditProfileTap,
    this.onAvatarTap,
  });

  final String displayName;
  final String? subtitle;
  final ImageProvider? photo;
  final bool avatarUploading;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final VoidCallback? onMyActivityTap;
  final VoidCallback? onWalletTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onEditProfileTap;
  final VoidCallback? onAvatarTap;

  String get _greetingName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'there';
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ProfileUiTokens.screenHorizontal,
        8,
        ProfileUiTokens.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showMenuButton) ...[
                IconButton(
                  onPressed: onMenuTap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 40),
                  icon: const Icon(Icons.menu_rounded, size: 24),
                  color: ProfileUiTokens.textPrimary,
                ),
                const SizedBox(width: 2),
              ],
              _Avatar(
                photo: photo,
                uploading: avatarUploading,
                onTap: onAvatarTap,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: onMyActivityTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: const StadiumBorder(),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    child: const Text('My Activity'),
                  ),
                ),
              ),
              const Spacer(),
              if (onWalletTap != null) ...[
                _IconBox(
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: onWalletTap,
                ),
                const SizedBox(width: 8),
              ],
              if (onNotificationsTap != null) _NotificationButton(onTap: onNotificationsTap),
              if (onSettingsTap != null)
                IconButton(
                  onPressed: onSettingsTap,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.settings_outlined, size: 24),
                  color: ProfileUiTokens.textPrimary,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $_greetingName!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            height: 1.15,
                            color: ProfileUiTokens.textPrimary,
                          ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ProfileUiTokens.textSecondary,
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditProfileTap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.only(left: 8, top: 4),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Edit profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photo, this.uploading = false, this.onTap});

  final ImageProvider? photo;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = ProfileUiTokens.avatarRadius;
    final avatar = CircleAvatar(
      radius: r,
      backgroundColor: ProfileUiTokens.bannerFill,
      backgroundImage: photo,
      child: photo == null
          ? Icon(Icons.person, size: r, color: ProfileUiTokens.textSecondary)
          : null,
    );

    Widget content = SizedBox(
      width: r * 2,
      height: r * 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          avatar,
          if (uploading)
            Positioned.fill(
              child: ClipOval(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.6),
                  child: Center(
                    child: SizedBox(
                      width: r,
                      height: r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: uploading ? null : onTap,
        customBorder: const CircleBorder(),
        child: content,
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ProfileUiTokens.iconBoxBorder),
          ),
          child: Icon(icon, size: 20, color: ProfileUiTokens.textPrimary),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, size: 24, color: ProfileUiTokens.textPrimary),
              Positioned(
                right: -1,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
