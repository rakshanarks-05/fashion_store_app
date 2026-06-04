import '../../../auth/domain/repositories/auth_repository.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

/// Updates Firestore `users/{uid}` editable fields and mirrors display name to Firebase Auth.
///
/// Email is never written here — use [ProfileRepository.updateUserEditableProfile].
class UpdateUserProfileUseCase {
  UpdateUserProfileUseCase(this._authRepository, this._profileRepository);
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  Future<void> call({
    required String userId,
    required String displayName,
    String? phoneNumberE164,
    String? photoUrl,
    String? address,
  }) async {
    await _authRepository.updateDisplayNameIfNeeded(displayName);

    final trimmedName = displayName.trim();
    final nameForDoc =
        trimmedName.isNotEmpty ? trimmedName : null;

    final phone = phoneNumberE164?.trim();
    final trimmedPhoto = photoUrl?.trim();
    final photoForDoc =
        trimmedPhoto != null && trimmedPhoto.isNotEmpty ? trimmedPhoto : null;

    final trimmedAddr = address?.trim();
    final addrForDoc =
        trimmedAddr != null && trimmedAddr.isNotEmpty ? trimmedAddr : null;

    await _profileRepository.updateUserEditableProfile(
      UserProfile(
        userId: userId,
        phoneNumber: phone != null && phone.isNotEmpty ? phone : null,
        displayName: nameForDoc,
        photoUrl: photoForDoc,
        address: addrForDoc,
      ),
    );
  }
}
