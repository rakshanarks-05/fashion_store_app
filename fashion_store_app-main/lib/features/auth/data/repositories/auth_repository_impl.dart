import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<AppUser> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _remote.signInWithEmail(email, password);
    final user = cred.user;
    if (user == null) {
      throw StateError('No user after login');
    }
    return AppUserModel.fromFirebase(user);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _remote.registerWithEmail(email, password);
    final user = cred.user;
    if (user == null) {
      throw StateError('No user after register');
    }
    return AppUserModel.fromFirebase(user);
  }

  @override
  Future<void> updateDisplayNameIfNeeded(String? displayName) async {
    final trimmed = displayName?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await _remote.updateDisplayName(trimmed);
  }

  @override
  Future<void> deleteAccount() => _remote.deleteCurrentUser();

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Stream<AppUser?> authStateChanges() {
    return _remote.authStateChanges().map((u) {
      if (u == null) return null;
      return AppUserModel.fromFirebase(u);
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _remote.sendPasswordResetEmail(email);
  }
}
