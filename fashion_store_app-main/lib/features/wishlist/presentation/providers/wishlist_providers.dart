import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/wishlist_remote_datasource.dart';
import '../../data/repositories/wishlist_repository_impl.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../../domain/usecases/get_wishlist_usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final wishlistRemoteDataSourceProvider =
    Provider<WishlistRemoteDataSource>((ref) {
  return WishlistRemoteDataSourceImpl(ref.watch(firebaseFirestoreProvider));
});

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepositoryImpl(ref.watch(wishlistRemoteDataSourceProvider));
});

final getWishlistUseCaseProvider = Provider<GetWishlistUseCase>((ref) {
  return GetWishlistUseCase(ref.watch(wishlistRepositoryProvider));
});

final wishlistForUserProvider = FutureProvider<List<WishlistItem>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final uid = user?.id;
  if (uid == null) return [];
  final useCase = ref.watch(getWishlistUseCaseProvider);
  return useCase(uid);
});
