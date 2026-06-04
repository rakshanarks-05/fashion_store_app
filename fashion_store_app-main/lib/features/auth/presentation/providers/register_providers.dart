import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/usecases/register_with_profile_usecase.dart';
import 'auth_providers.dart';

final registerWithProfileUseCaseProvider =
    Provider<RegisterWithProfileUseCase>((ref) {
  return RegisterWithProfileUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});
