import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_drawer.dart';
import '../providers/wishlist_providers.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wishlistForUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      drawer: const AppDrawer(),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No saved items. Sign in to use your wishlist.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final w = items[i];
              return ListTile(
                title: Text('Product ${w.productId}'),
                leading: const Icon(Icons.favorite_outline),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
