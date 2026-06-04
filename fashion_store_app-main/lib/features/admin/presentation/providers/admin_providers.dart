import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firestore_create/services/firestore_create_service.dart';
import '../../../../core/providers/core_providers.dart';

final firestoreCreateServiceProvider = Provider<FirestoreCreateService>((ref) {
  return FirestoreCreateService(ref.watch(firebaseFirestoreProvider));
});
