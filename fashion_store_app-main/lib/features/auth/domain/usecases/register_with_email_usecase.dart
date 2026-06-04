import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailUseCase {
  RegisterWithEmailUseCase(this._repository);
  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
  }) {
    return _repository.registerWithEmail(email: email, password: password);
  }
}
