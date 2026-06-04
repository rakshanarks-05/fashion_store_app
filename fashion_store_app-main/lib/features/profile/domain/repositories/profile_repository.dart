import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getProfile(String userId);

  Future<void> saveUserProfile(UserProfile profile);

  /// Merges editable fields only; does **not** write `email` (account email stays unchanged).
  Future<void> updateUserEditableProfile(UserProfile profile);
}
