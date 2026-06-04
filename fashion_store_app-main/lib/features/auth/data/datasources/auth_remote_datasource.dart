import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> registerWithEmail(String email, String password);
  Future<void> signOut();
  Stream<User?> authStateChanges();

  /// Updates the currently signed-in user's display name (no-op if not signed in).
  Future<void> updateDisplayName(String displayName);

  /// Deletes the currently signed-in Firebase Auth user (used to roll back failed registration).
  Future<void> deleteCurrentUser();

  Future<void> sendPasswordResetEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth);
  final FirebaseAuth _auth;

  @override
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName);
  }

  @override
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user to delete');
    }
    await user.delete();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }
}
