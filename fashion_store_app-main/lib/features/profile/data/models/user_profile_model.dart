import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    super.email,
    super.phoneNumber,
    super.displayName,
    super.photoUrl,
    super.address,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json, String userId) {
    return UserProfileModel(
      userId: userId,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      address: json['address'] as String?,
    );
  }

  /// Payload for `users/{uid}` — aligns with registration and profile reads.
  Map<String, dynamic> toJson() => {
        'email': email,
        'phoneNumber': phoneNumber,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'address': address,
      };

  /// Firestore merge map for profile updates — **omits `email`** so it cannot be changed here.
  Map<String, dynamic> toEditableFirestoreMap() {
    return {
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'address': address,
    };
  }
}
