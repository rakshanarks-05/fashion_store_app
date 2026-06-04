import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_user_profile_usecase.dart';
import '../../domain/usecases/update_user_profile_usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(ref.watch(firebaseFirestoreProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  return GetUserProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>(
  (ref) {
    return UpdateUserProfileUseCase(
      ref.watch(authRepositoryProvider),
      ref.watch(profileRepositoryProvider),
    );
  },
);

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final uid = user?.id;
  if (uid == null) return null;
  final useCase = ref.watch(getUserProfileUseCaseProvider);
  return useCase(uid);
});
