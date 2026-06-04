import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel?> fetchProfile(String userId);

  /// Creates or overwrites the signed-in user's document at `users/{userId}`.
  Future<void> saveUserProfile(UserProfileModel profile);

  /// Merges [fields] into `users/{userId}` — caller must omit `email` when appropriate.
  Future<void> mergeUserProfileFields(
    String userId,
    Map<String, dynamic> fields,
  );
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Future<UserProfileModel?> fetchProfile(String userId) async {
    final doc = await _firestore.doc(FirestorePaths.userDoc(userId)).get();
    if (!doc.exists || doc.data() == null) {
      return UserProfileModel(userId: userId);
    }
    return UserProfileModel.fromJson(doc.data()!, userId);
  }

  @override
  Future<void> saveUserProfile(UserProfileModel profile) async {
    await _firestore
        .doc(FirestorePaths.userDoc(profile.userId))
        .set(profile.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> mergeUserProfileFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    await _firestore
        .doc(FirestorePaths.userDoc(userId))
        .set(fields, SetOptions(merge: true));
  }
}
