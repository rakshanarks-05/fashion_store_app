import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/feature_flags.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Fashion Store',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Products'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Cart'),
              onTap: () => _go(context, '/cart'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => _go(context, '/profile'),
            ),
            const Divider(),
            auth.when(
              data: (user) {
                if (user == null) {
                  return ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign in'),
                    onTap: () => _go(context, '/login'),
                  );
                }
                return ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authRepositoryProvider).signOut();
                  },
                );
              },
              loading: () => const ListTile(
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Account'),
              ),
              error: (Object e, StackTrace _) => ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Sign in'),
                onTap: () => _go(context, '/login'),
              ),
            ),
            if (FeatureFlags.enableAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Admin'),
                onTap: () => _go(context, '/admin'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
