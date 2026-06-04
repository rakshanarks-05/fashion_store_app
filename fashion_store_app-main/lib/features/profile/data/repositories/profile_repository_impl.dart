import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/user_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<UserProfile?> getProfile(String userId) {
    return _remote.fetchProfile(userId);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return _remote.saveUserProfile(
      UserProfileModel(
        userId: profile.userId,
        email: profile.email,
        phoneNumber: profile.phoneNumber,
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
        address: profile.address,
      ),
    );
  }

  @override
  Future<void> updateUserEditableProfile(UserProfile profile) {
    final model = UserProfileModel(
      userId: profile.userId,
      email: profile.email,
      phoneNumber: profile.phoneNumber,
      displayName: profile.displayName,
      photoUrl: profile.photoUrl,
      address: profile.address,
    );
    return _remote.mergeUserProfileFields(
      profile.userId,
      model.toEditableFirestoreMap(),
    );
  }
}
