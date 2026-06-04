import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/models/shop_catalog.dart';
import '../../../product/presentation/providers/product_providers.dart';
import '../../../product/presentation/widgets/add_to_cart_sheet.dart';
import '../../../product/presentation/widgets/shop_bottom_navigation_bar.dart';
import '../models/cart_resolved_line.dart';
import '../providers/cart_providers.dart';
import '../providers/cart_ui_providers.dart';
import '../theme/cart_tokens.dart';
import '../utils/cart_formatters.dart';
import '../widgets/cart_checkout_bar.dart';
import '../widgets/cart_empty_state.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/cart_shipping_address_card.dart';
import '../widgets/cart_wishlist_row_widget.dart';

/// Cart screen — layout matches the fashion cart reference (shipping, lines, wishlist, checkout).
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  static const int _navCartIndex = 3;
  String? _selectedProductId;

  void _onNavTap(int index) {
    if (index == _navCartIndex) return;
    final nav = Navigator.of(context);
    switch (index) {
      case 0:
        nav.pushNamedAndRemoveUntil('/', (route) => false);
        break;
      case 1:
        nav.pushNamed('/wishlist');
        break;
      case 2:
        nav.pushNamed('/orders');
        break;
      case 4:
        nav.pushNamed('/profile');
        break;
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _editShipping(String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Shipping address'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Street, city, district',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      ref.read(cartShippingAddressProvider.notifier).state = result;
    }
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'Remove all items from your cart. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(cartNotifierProvider.notifier).clear();
    }
  }

  Future<void> _editCartItem(CartResolvedLine line) async {
    final product = line.product;
    if (product == null) {
      _snack('Product details are still loading. Try again in a moment.');
      return;
    }
    final imageUrls = ref.read(productImageUrlsByIdProvider(product.id));
    final sheetProduct = ShopCatalog.productToShopItem(product);
    final notifier = ref.read(cartNotifierProvider.notifier);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => AddToCartSheet(
        product: sheetProduct,
        availableSizes: AddToCartSheetDefaults.sizes,
        productImageUrls: imageUrls,
        initialQuantity: line.cartItem.quantity,
        initialSize: line.cartItem.selectedSize,
        addToCartButtonLabel: 'Save Changes',
        onAddToCart: (quantity, size) =>
            notifier.setItemSelection(
              line.productId,
              quantity: quantity,
              selectedSize: size,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: CartTokens.background,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: CartTokens.textPrimary,
              displayColor: CartTokens.textPrimary,
            ),
      ),
      child: Scaffold(
        backgroundColor: CartTokens.background,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer(
              builder: (context, ref, _) {
                final cart = ref.watch(cartNotifierProvider);
                final total = ref.watch(cartOrderTotalProvider);
                if (!cart.isGuest &&
                    !cart.loading &&
                    cart.items.isNotEmpty) {
                  return CartCheckoutBar(
                    total: total,
                    onCheckout: () =>
                        Navigator.of(context).pushNamed('/checkout'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ShopHomeBottomNavigationBar(
              currentIndex: _navCartIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Consumer(
            builder: (context, ref, _) {
              ref.listen<CartState>(cartNotifierProvider, (prev, next) {
                final msg = next.errorMessage;
                if (msg != null &&
                    msg.isNotEmpty &&
                    (prev == null || prev.errorMessage != msg)) {
                  _snack(msg);
                }
              });
              final cart = ref.watch(cartNotifierProvider);
              final notifier = ref.read(cartNotifierProvider.notifier);
              final lines = ref.watch(cartResolvedLinesProvider);
              final wishlist = ref.watch(wishlistProductsForCartProvider);
              final categoryMap =
                  ref.watch(categoryIdToNameProvider).valueOrNull ??
                      const <String, String>{};
              final shipping =
                  ref.watch(resolvedCartShippingAddressProvider);

              return cart.isGuest
                  ? _GuestCart(
                      onSignIn: () =>
                          Navigator.of(context).pushNamed('/login'),
                    )
                  : _buildSignedInBody(
                      cart: cart,
                      notifier: notifier,
                      lines: lines,
                      wishlist: wishlist,
                      categoryMap: categoryMap,
                      shipping: shipping,
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSignedInBody({
    required CartState cart,
    required CartNotifier notifier,
    required List<CartResolvedLine> lines,
    required List<Product> wishlist,
    required Map<String, String> categoryMap,
    required String shipping,
  }) {
    if (cart.loading && cart.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cart.items.isEmpty &&
        !cart.loading &&
        cart.errorMessage != null) {
      return _CartLoadError(
        message: cart.errorMessage!,
        onRetry: () => notifier.refresh(),
      );
    }

    if (lines.isEmpty) {
      return CartEmptyState(
        onContinueShopping: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            ),
      );
    }

    final ids = lines.map((l) => l.productId).toList(growable: false);
    if (_selectedProductId == null || !ids.contains(_selectedProductId)) {
      _selectedProductId = ids.first;
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _CartHeader(
            count: cart.items.length,
            onClearAll:
                cart.items.isEmpty ? null : () => _confirmClearAll(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              CartTokens.horizontalPadding,
              8,
              CartTokens.horizontalPadding,
              0,
            ),
            child: CartShippingAddressCard(
              address: shippingAddressDisplayLabel(shipping),
              onEdit: () => _editShipping(shipping),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: CartTokens.horizontalPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final line = lines[index];
                final catName = line.product == null
                    ? null
                    : categoryMap[line.product!.categoryId];
                final subtitle = productCartSubtitle(
                  line.product,
                  catName,
                  selectedSize: line.cartItem.selectedSize,
                );
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == lines.length - 1 ? 0 : 12,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(CartTokens.cardRadius),
                    onTap: () => setState(() => _selectedProductId = line.productId),
                    child: CartItemWidget(
                      line: line,
                      subtitle: subtitle,
                      selected: line.productId == _selectedProductId,
                      onEdit: () => _editCartItem(line),
                      onRemove: () => notifier.remove(line.productId),
                      onDecrement: () =>
                          notifier.decrementQuantity(line.productId),
                      onIncrement: () =>
                          notifier.incrementQuantity(line.productId),
                    ),
                  ),
                );
              },
              childCount: lines.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: wishlist.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: CartTokens.horizontalPadding,
                      ),
                      child: Text(
                        'From Your Wishlist',
                        style: TextStyle(
                          fontSize: CartTokens.sectionTitleSize,
                          fontWeight: FontWeight.w800,
                          color: CartTokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CartTokens.horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < wishlist.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                top: i == 0 ? 0 : 12,
                              ),
                              child: CartWishlistRowWidget(
                                product: wishlist[i],
                                chips: wishlistAttributeChips(
                                  wishlist[i],
                                  categoryMap[wishlist[i].categoryId],
                                ),
                                onAddToCart: () async {
                                  final ok =
                                      await notifier.add(wishlist[i].id);
                                  if (!mounted) return;
                                  if (!ok) {
                                    _snack('Sign in to add items.');
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _CartLoadError extends StatelessWidget {
  const _CartLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CartTokens.horizontalPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: CartTokens.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: CartTokens.bodySize,
                color: CartTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.count,
    this.onClearAll,
  });

  final int count;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CartTokens.horizontalPadding,
        8,
        CartTokens.horizontalPadding,
        12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Cart',
            style: TextStyle(
              fontSize: CartTokens.titleSize,
              fontWeight: FontWeight.w800,
              color: CartTokens.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CartTokens.badgeFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CartTokens.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          if (onClearAll != null)
            IconButton(
              tooltip: 'Clear cart',
              onPressed: onClearAll,
              icon: Icon(
                Icons.delete_sweep_outlined,
                color: CartTokens.textSecondary.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuestCart extends StatelessWidget {
  const _GuestCart({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CartHeader(count: 0),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CartTokens.horizontalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: CartTokens.textSecondary.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in to view your cart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: CartTokens.sectionTitleSize,
                      fontWeight: FontWeight.w700,
                      color: CartTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your cart is saved to your account after you sign in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: CartTokens.bodySize,
                      color: CartTokens.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
