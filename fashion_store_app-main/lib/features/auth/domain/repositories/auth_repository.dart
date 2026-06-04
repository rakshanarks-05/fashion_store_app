import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  });

  /// Sets Firebase Auth profile display name when [displayName] is non-empty.
  Future<void> updateDisplayNameIfNeeded(String? displayName);

  /// Removes the current Firebase Auth account (registration rollback).
  Future<void> deleteAccount();

  Future<void> signOut();

  Stream<AppUser?> authStateChanges();

  Future<void> sendPasswordResetEmail(String email);
}
