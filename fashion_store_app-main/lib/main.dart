import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/firebase_bootstrap.dart';

Future<void> main() async {
  await bootstrapFirebase();
  runApp(const ProviderScope(child: FashionStoreApp()));
}
