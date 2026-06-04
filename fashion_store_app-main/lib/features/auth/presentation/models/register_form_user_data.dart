import '../../../profile/domain/entities/user_profile.dart';

/// Data passed into [RegisterPage] edit mode (home → register) or used as a “logged-in user” DTO.
class RegisterFormUserData {
  const RegisterFormUserData({
    required this.userId,
    this.email,
    this.displayName,
    this.phoneNumberE164,
    this.photoUrl,
    this.address,
  });

  final String userId;
  final String? email;
  final String? displayName;
  final String? phoneNumberE164;
  final String? photoUrl;
  final String? address;

  /// Builds form seed data from Firebase Auth + optional Firestore profile.
  factory RegisterFormUserData.merge({
    required String userId,
    String? authEmail,
    UserProfile? profile,
  }) {
    return RegisterFormUserData(
      userId: userId,
      email: (authEmail != null && authEmail.isNotEmpty)
          ? authEmail
          : profile?.email,
      displayName: profile?.displayName,
      phoneNumberE164: profile?.phoneNumber,
      photoUrl: profile?.photoUrl,
      address: profile?.address,
    );
  }
}
