import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../wishlist/presentation/providers/wishlist_providers.dart';
import '../models/cart_resolved_line.dart';
import '../utils/cart_formatters.dart';
import 'cart_providers.dart';

/// Optional override when the user edits shipping on cart / checkout / payment.
/// Empty means “use [resolvedCartShippingAddressProvider]” (saved profile address).
final cartShippingAddressProvider = StateProvider<String>((ref) => '');

/// Delivery line for checkout: session override if set, otherwise Firestore profile `address`.
final resolvedCartShippingAddressProvider = Provider<String>((ref) {
  final session = ref.watch(cartShippingAddressProvider).trim();
  if (session.isNotEmpty) return session;
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final saved = profile?.address?.trim();
  if (saved != null && saved.isNotEmpty) return saved;
  return '';
});

/// Copy for cards when there is no session override and no saved profile address.
String shippingAddressDisplayLabel(String resolved) {
  final t = resolved.trim();
  if (t.isNotEmpty) return t;
  return 'No delivery address yet. Save one in Profile (Edit profile), or tap edit to add.';
}

/// Cart lines merged with the latest product stream snapshot.
/// [product] is null until that product appears in the stream (e.g. still loading).
final cartResolvedLinesProvider = Provider<List<CartResolvedLine>>((ref) {
  final items = ref.watch(cartNotifierProvider.select((s) => s.items));
  final productsAsync = ref.watch(productListProvider);
  final products = productsAsync.valueOrNull ?? [];
  final map = {for (final p in products) p.id: p};
  return items
      .map(
        (item) => CartResolvedLine(
          cartItem: item,
          product: map[item.productId],
        ),
      )
      .toList(growable: false);
});

/// Order total (subtotal when no delivery fee is modeled).
final cartOrderTotalProvider = Provider<double>((ref) {
  final lines = ref.watch(cartResolvedLinesProvider);
  return computeCartOrderTotal(lines);
});

/// Wishlist products not already in the cart (for “From Your Wishlist”).
final wishlistProductsForCartProvider = Provider<List<Product>>((ref) {
  final wishlistAsync = ref.watch(wishlistForUserProvider);
  final wishlist = wishlistAsync.valueOrNull ?? [];
  final productsAsync = ref.watch(productListProvider);
  final products = productsAsync.valueOrNull ?? [];
  final cartIds = ref
      .watch(cartNotifierProvider.select((s) => s.items))
      .map((e) => e.productId)
      .toSet();
  final map = {for (final p in products) p.id: p};
  final out = <Product>[];
  for (final w in wishlist) {
    final p = map[w.productId];
    if (p != null && !cartIds.contains(p.id)) {
      out.add(p);
    }
  }
  return out;
});
