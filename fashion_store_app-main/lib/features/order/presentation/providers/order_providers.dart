import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/services/order_service.dart';
import '../../domain/entities/order_model.dart';
import '../../domain/repositories/order_repository.dart';

export 'order_placement_controller.dart';

/// Low-level Firestore order API (create, query, status updates).
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(ref.watch(firebaseFirestoreProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(orderServiceProvider));
});

/// Live Firestore stream of orders for the signed-in user (newest first).
///
/// Rebuilds when [authStateProvider] changes; [uid] matches
/// [FirebaseAuth.instance.currentUser]?.uid when signed in.
final ordersForUserProvider = StreamProvider<List<OrderModel>>((ref) {
  ref.watch(authStateProvider);
  final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
  if (uid == null || uid.isEmpty) {
    return Stream<List<OrderModel>>.value(<OrderModel>[]);
  }
  return ref.watch(orderServiceProvider).watchUserOrdersStream(uid);
});
