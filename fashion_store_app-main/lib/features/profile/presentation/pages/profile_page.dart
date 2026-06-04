import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/models/register_form_user_data.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../product/presentation/theme/shop_tokens.dart';
import '../../../product/presentation/widgets/shop_bottom_navigation_bar.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';
import '../utils/profile_photo_cloudinary.dart';
import '../theme/profile_ui_tokens.dart';
import '../widgets/profile_announcement_banner.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_option_tile.dart';
import '../widgets/profile_order_status_chips.dart';
import '../widgets/profile_recently_viewed_row.dart';
import '../widgets/profile_section_title.dart';
import '../widgets/profile_stories_row.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const _navProfileIndex = 4;

  bool _profilePhotoUploading = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _onBottomNavTap(int index) {
    final nav = Navigator.of(context);
    switch (index) {
      case 0:
        nav.popUntil((r) => r.isFirst);
        break;
      case 1:
        nav.pushNamed('/wishlist');
        break;
      case 2:
        nav.pushNamed('/orders');
        break;
      case 3:
        nav.pushNamed('/cart');
        break;
      case 4:
        break;
    }
  }

  ImageProvider? _avatarFor(UserProfile? profile) {
    final url = profile?.photoUrl;
    if (url == null || url.isEmpty) return null;
    return NetworkImage(url);
  }

  Future<void> _openEditProfile() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      _snack('Sign in to edit your profile.');
      return;
    }
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => RegisterPage(
            isEditMode: true,
            initialUserData: RegisterFormUserData.merge(
              userId: user.id,
              authEmail: user.email,
              profile: profile,
            ),
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Edit profile navigation: $e\n$st');
      if (!mounted) return;
      _snack('Could not open edit profile. Please try again.');
    }
  }

  Future<void> _updateProfilePhotoFromCloudinary(UserProfile? profile) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final url = await pickAndUploadProfilePhotoToCloudinary(
      context,
      ref,
      onUploading: (uploading) {
        if (mounted) setState(() => _profilePhotoUploading = uploading);
      },
      accentColor: Theme.of(context).colorScheme.primary,
    );
    if (url == null || !mounted) return;

    await ref.read(profileRepositoryProvider).saveUserProfile(
          UserProfile(
            userId: user.id,
            email: profile?.email ?? user.email,
            phoneNumber: profile?.phoneNumber,
            displayName: profile?.displayName,
            photoUrl: url,
            address: profile?.address,
          ),
        );
    ref.invalidate(userProfileProvider);
    _snack('Profile photo updated');
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: ProfileUiTokens.pageBackground,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: ProfileUiTokens.textPrimary,
              displayColor: ProfileUiTokens.textPrimary,
            ),
      ),
      child: Scaffold(
        drawer: const AppDrawer(),
        bottomNavigationBar: ShopHomeBottomNavigationBar(
          currentIndex: _navProfileIndex,
          onTap: _onBottomNavTap,
        ),
        body: SafeArea(
          bottom: false,
          child: Consumer(
            builder: (context, ref, _) {
              final auth = ref.watch(authStateProvider);
              final user = auth.valueOrNull;
              final profileAsync = ref.watch(userProfileProvider);

              return user == null
                  ? _GuestProfileScroll(
                      onSignIn: () =>
                          Navigator.of(context).pushNamed('/login'),
                      onSnack: _snack,
                    )
                  : profileAsync.when(
                      data: (profile) => _SignedInProfileScroll(
                        profile: profile,
                        avatar: _avatarFor(profile),
                        accountEmail: user.email,
                        profilePhotoUploading: _profilePhotoUploading,
                        onSnack: _snack,
                        onOpenEditProfile: _openEditProfile,
                        onChangeProfilePhoto: () =>
                            _updateProfilePhotoFromCloudinary(profile),
                        onLogout: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) {
                            _snack('Signed out');
                          }
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('$e')),
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _SignedInProfileScroll extends StatelessWidget {
  const _SignedInProfileScroll({
    required this.profile,
    required this.avatar,
    this.accountEmail,
    this.profilePhotoUploading = false,
    required this.onSnack,
    required this.onOpenEditProfile,
    required this.onChangeProfilePhoto,
    required this.onLogout,
  });

  final UserProfile? profile;
  final ImageProvider? avatar;
  final String? accountEmail;
  final bool profilePhotoUploading;
  final void Function(String) onSnack;
  final Future<void> Function() onOpenEditProfile;
  final VoidCallback onChangeProfilePhoto;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName?.trim().isNotEmpty == true
        ? profile!.displayName!.trim()
        : 'Fashion lover';
    final subtitle = accountEmail != null && accountEmail!.isNotEmpty
        ? accountEmail!
        : 'Member · ID ${profile?.userId ?? '—'}';

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 72,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  displayName: name,
                  subtitle: subtitle,
                  photo: avatar,
                  avatarUploading: profilePhotoUploading,
                  showMenuButton: true,
                  onMenuTap: () => Scaffold.of(context).openDrawer(),
                  onMyActivityTap: () => onSnack('My Activity'),
                  onEditProfileTap: () => onOpenEditProfile(),
                  onAvatarTap: onChangeProfilePhoto,
                ),
                const SizedBox(height: ProfileUiTokens.sectionGap),
                ProfileAnnouncementBanner(
                  onTap: () => onSnack('Open announcement'),
                ),
                const SizedBox(height: ProfileUiTokens.sectionGap),
                const SizedBox(height: ProfileUiTokens.sectionGap + 8),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                const SizedBox(height: 20),
                const SectionTitle('Account'),
                const SizedBox(height: 4),
                ProfileOptionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'My Orders',
                  onTap: () => Navigator.of(context).pushNamed('/orders'),
                ),
                ProfileOptionTile(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  onTap: () => onSnack('Payment methods'),
                ),
                ProfileOptionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () => onSnack('Notification preferences'),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                const SizedBox(height: 20),
                const SectionTitle('Settings'),
                const SizedBox(height: 4),
                ProfileOptionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => onSnack('Privacy Policy'),
                ),
                ProfileOptionTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => onSnack('Terms & Conditions'),
                ),
                ProfileOptionTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () => onSnack('Help & Support'),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProfileUiTokens.screenHorizontal,
                  ),
                  child: OutlinedButton(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ShopTokens.saleBadge,
                      side: BorderSide(color: ShopTokens.saleBadge.withValues(alpha: 0.65)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuestProfileScroll extends StatelessWidget {
  const _GuestProfileScroll({
    required this.onSignIn,
    required this.onSnack,
  });

  final VoidCallback onSignIn;
  final void Function(String) onSnack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 72,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  displayName: 'Guest',
                  subtitle: 'Sign in to sync orders and wishlist',
                  photo: null,
                  showMenuButton: true,
                  onMenuTap: () => Scaffold.of(context).openDrawer(),
                  onMyActivityTap: () => onSnack('Sign in to view activity'),
                  onEditProfileTap: onSignIn,
                ),
                const SizedBox(height: ProfileUiTokens.sectionGap),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProfileUiTokens.screenHorizontal,
                  ),
                  child: FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ProfileUiTokens.cardRadius),
                      ),
                    ),
                    child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: ProfileUiTokens.sectionGap),
                ProfileAnnouncementBanner(onTap: () => onSnack('Open announcement')),
                const SizedBox(height: ProfileUiTokens.sectionGap),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
