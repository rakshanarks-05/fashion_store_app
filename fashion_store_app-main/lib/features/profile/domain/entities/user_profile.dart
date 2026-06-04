import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.address,
  });

  final String userId;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final String? address;

  @override
  List<Object?> get props =>
      [userId, email, phoneNumber, displayName, photoUrl, address];
}
