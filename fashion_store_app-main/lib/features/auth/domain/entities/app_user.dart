import 'package:equatable/equatable.dart';

/// Firebase Auth identity (uid + email). Extended profile fields are stored in Firestore (`UserProfile`).
class AppUser extends Equatable {
  const AppUser({required this.id, this.email});

  final String id;
  final String? email;

  @override
  List<Object?> get props => [id, email];
}
