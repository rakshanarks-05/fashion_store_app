import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Registers with email/password, sets optional Auth display name, writes `users/{uid}`.
///
/// [phoneNumberE164] is optional; when omitted or empty, no phone is stored on the profile.
///
/// If any step after [AuthRepository.registerWithEmail] fails, the Firebase Auth user
/// is deleted so the account is not left without a Firestore profile.
class RegisterWithProfileUseCase {
  RegisterWithProfileUseCase(this._authRepository, this._profileRepository);
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  Future<AppUser> call({
    required String email,
    required String password,
    String? phoneNumberE164,
    String? displayName,
    String? photoUrl,
    String? address,
  }) async {
    AppUser? created;
    try {
      // 1) Firebase Auth account (user becomes signed in).
      created = await _authRepository.registerWithEmail(
        email: email.trim(),
        password: password,
      );

      // 2) Optional Firebase Auth profile (mirrors Firestore displayName when set).
      await _authRepository.updateDisplayNameIfNeeded(displayName);

      final trimmedName = displayName?.trim();
      final nameForDoc =
          trimmedName != null && trimmedName.isNotEmpty ? trimmedName : null;

      final trimmedPhoto = photoUrl?.trim();
      final photoForDoc =
          trimmedPhoto != null && trimmedPhoto.isNotEmpty ? trimmedPhoto : null;

      final trimmedAddr = address?.trim();
      final addrForDoc =
          trimmedAddr != null && trimmedAddr.isNotEmpty ? trimmedAddr : null;

      // 3) Persist profile document for the app (email, phone, optional name/photo).
      final phone = phoneNumberE164?.trim();
      await _profileRepository.saveUserProfile(
        UserProfile(
          userId: created.id,
          email: email.trim(),
          phoneNumber: phone != null && phone.isNotEmpty ? phone : null,
          displayName: nameForDoc,
          photoUrl: photoForDoc,
          address: addrForDoc,
        ),
      );

      return created;
    } catch (e) {
      if (created != null) {
        try {
          await _authRepository.deleteAccount();
        } catch (_) {
          // Rollback is best-effort; original failure is still thrown.
        }
      }
      rethrow;
    }
  }
}
