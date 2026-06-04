import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/pages/admin_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/checkout/presentation/screens/checkout/checkout_page.dart';
import 'features/payment/presentation/screens/payment/payment_method_screen.dart';
import 'features/order/presentation/pages/orders_page.dart';
import 'features/product/presentation/pages/product_list_page.dart';
import 'features/product/presentation/pages/product_page.dart';
import 'features/category/presentation/screens/all_categories_screen.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/wishlist/presentation/pages/wishlist_page.dart';

class FashionStoreApp extends ConsumerWidget {
  const FashionStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light().copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const ProductPage(),
        '/browse': (_) => const ProductListPage(),
        '/categories': (_) => const AllCategoriesScreen(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/cart': (_) => const CartPage(),
        '/checkout': (_) => const CheckoutPage(),
        '/payment': (_) => const PaymentMethodScreen(),
        '/wishlist': (_) => const WishlistPage(),
        '/orders': (_) => const OrdersPage(),
        '/profile': (_) => const ProfilePage(),
        '/admin': (_) => const AdminPage(),
        '/create-mode': (_) => const AdminPage(),
      },
    );
  }
}
