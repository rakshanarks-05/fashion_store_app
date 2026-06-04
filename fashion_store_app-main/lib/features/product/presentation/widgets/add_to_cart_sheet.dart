import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/cart_quantity_selector.dart';
import '../../../../core/widgets/product_network_image.dart';
import '../models/shop_catalog.dart';
import '../theme/shop_tokens.dart';

typedef AddToCartSelection = ({
  String? size,
});

typedef AddToCartSubmit = Future<bool> Function(int quantity, String? size);

Future<void> showAddToCartSheet(
  BuildContext context, {
  required ShopProductItem product,
  List<String> availableSizes = AddToCartSheetDefaults.sizes,
  List<String>? productImageUrls,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => AddToCartSheet(
      product: product,
      availableSizes: availableSizes,
      productImageUrls: productImageUrls,
    ),
  );
}

Future<void> showAddToCartSheetIfSignedIn(
  BuildContext context,
  WidgetRef ref, {
  required ShopProductItem product,
  List<String> availableSizes = AddToCartSheetDefaults.sizes,
  List<String>? productImageUrls,
}) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in to add items to your cart.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  await showAddToCartSheet(
    context,
    product: product,
    availableSizes: availableSizes,
    productImageUrls: productImageUrls,
  );
}

abstract final class AddToCartSheetDefaults {
  static const sizes = <String>['S', 'M', 'L', 'XL'];

  static const double sheetRadius = 22;
  static const double sheetHorizontalPadding = 18;
  static const double headerIconSize = 18;
  static const double primaryButtonHeight = 48;
}

/// UI tokens for the current Home theme (coral accent + neutral grays).
abstract final class _AddToCartTheme {
  static const Color accent = Color(0xFFF07D74);
  static const Color surface = Colors.white;
  static const Color softGray = Color(0xFFF3F3F3);
  static const Color midGray = Color(0xFFE9E9E9);
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color textPrimary = ShopTokens.textPrimary;
  static const Color textSecondary = ShopTokens.textSecondary;
}

class AddToCartSheet extends ConsumerStatefulWidget {
  const AddToCartSheet({
    super.key,
    required this.product,
    required this.availableSizes,
    this.productImageUrls,
    this.initialQuantity = 1,
    this.initialSize,
    this.addToCartButtonLabel = 'Add to Cart',
    this.onAddToCart,
  });

  final ShopProductItem product;
  final List<String> availableSizes;
  final List<String>? productImageUrls;
  final int initialQuantity;
  final String? initialSize;
  final String addToCartButtonLabel;
  final AddToCartSubmit? onAddToCart;

  @override
  ConsumerState<AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends ConsumerState<AddToCartSheet> {
  int _quantity = 1;
  String? _selectedSize;
  int _activeImageIndex = 0;
  bool _submitting = false;
  String? _errorText;
  late final PageController _pageController;

  List<String> get _galleryImages {
    final source = widget.productImageUrls ?? <String>[widget.product.imageUrl];
    final out = source.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (out.isNotEmpty) return out;
    return const <String>[''];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _quantity = widget.initialQuantity < 1 ? 1 : widget.initialQuantity;
    final normalizedSize = widget.initialSize?.trim();
    if (widget.availableSizes.isEmpty) {
      _selectedSize = normalizedSize;
    } else if (normalizedSize != null && widget.availableSizes.contains(normalizedSize)) {
      _selectedSize = normalizedSize;
    } else {
      _selectedSize = null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _selectionLabel() {
    final parts = <String>[];
    if (_selectedSize != null && _selectedSize!.trim().isNotEmpty) {
      parts.add('Size ${_selectedSize!}');
    }
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  Future<void> _onAddToCart() async {
    if (_submitting) return;
    if (widget.availableSizes.isNotEmpty && _selectedSize == null) {
      setState(() => _errorText = 'Please choose a size before adding to cart.');
      _snack('Select a size to continue.');
      return;
    }
    setState(() => _errorText = null);
    setState(() => _submitting = true);
    final ok = widget.onAddToCart != null
        ? await widget.onAddToCart!(_quantity, _selectedSize)
        : await ref
            .read(cartNotifierProvider.notifier)
            .addWithQuantity(
              widget.product.id,
              _quantity,
              selectedSize: _selectedSize,
            );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      _snack('Sign in to add items to your cart.');
      return;
    }
    final successText = widget.onAddToCart != null
        ? 'Cart updated${_selectionLabel()}'
        : 'Added to cart${_selectionLabel()}';
    _snack(successText);
    _close();
  }

  void _goToNextImage() {
    if (_galleryImages.length <= 1) return;
    final next = (_activeImageIndex + 1) % _galleryImages.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousImage() {
    if (_galleryImages.length <= 1) return;
    final prev = (_activeImageIndex - 1 + _galleryImages.length) % _galleryImages.length;
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.9;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _SheetSurface(
            child: SafeArea(
              top: false,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - value) * 24),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: _SheetHeader(onClose: _close),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            14,
                            8,
                            14,
                            12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ImageGalleryBlock(
                                images: _galleryImages,
                                activeIndex: _activeImageIndex,
                                pageController: _pageController,
                                onIndexChanged: (index) =>
                                    setState(() => _activeImageIndex = index),
                                onPrevious: _goToPreviousImage,
                                onNext: _goToNextImage,
                              ),
                              const SizedBox(height: 12),
                              _ProductInfoCard(
                                product: widget.product,
                                quantity: _quantity,
                                selectedSize: _selectedSize,
                                availableSizes: widget.availableSizes,
                                errorText: _errorText,
                                onDecrement: _quantity <= 1
                                    ? null
                                    : () => setState(() => _quantity -= 1),
                                onIncrement: () => setState(() => _quantity += 1),
                                onSizeSelected: (size) {
                                  setState(() {
                                    _selectedSize = size;
                                    _errorText = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      _StickyCtaBar(
                        totalPrice: widget.product.price * _quantity,
                        onBuyNow: () => _snack('Buy Now can be added next.'),
                        onAddToCart: _submitting ? null : _onAddToCart,
                        addToCartLabel:
                            _submitting ? 'Saving…' : widget.addToCartButtonLabel,
                        colorScheme: scheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AddToCartTheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AddToCartSheetDefaults.sheetRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _IconCircleButton(
          icon: Icons.close,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _ImageGalleryBlock extends StatelessWidget {
  const _ImageGalleryBlock({
    required this.images,
    required this.activeIndex,
    required this.pageController,
    required this.onIndexChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final List<String> images;
  final int activeIndex;
  final PageController pageController;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AddToCartTheme.softGray,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AddToCartTheme.borderGray),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.sizeOf(context).height;
              final upperBound = screenHeight * 0.30 < 180 ? 180.0 : screenHeight * 0.30;
              final galleryHeight =
                  (constraints.maxWidth * 0.50).clamp(165.0, upperBound).toDouble();

              return SizedBox(
                height: galleryHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: pageController,
                      itemCount: images.length,
                      onPageChanged: onIndexChanged,
                      itemBuilder: (context, index) {
                        final imageUrl = images[index].trim();
                        return AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: activeIndex == index ? 1 : 0.95,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: imageUrl.isEmpty
                                  ? ColoredBox(
                                      color: Colors.white,
                                      child: Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    )
                                  : ProductNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (images.length > 1) ...[
                      Positioned(
                        left: 2,
                        child: _ArrowButton(
                          icon: Icons.keyboard_arrow_left_rounded,
                          onPressed: onPrevious,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        child: _ArrowButton(
                          icon: Icons.keyboard_arrow_right_rounded,
                          onPressed: onNext,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 6),
            _DotsIndicator(length: images.length, activeIndex: activeIndex),
          ],
        ],
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({
    required this.product,
    required this.quantity,
    required this.selectedSize,
    required this.availableSizes,
    required this.errorText,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSizeSelected,
  });

  final ShopProductItem product;
  final int quantity;
  final String? selectedSize;
  final List<String> availableSizes;
  final String? errorText;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onSizeSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AddToCartTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: ShopTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Rs. ${product.price.toStringAsFixed(2)}',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ShopTokens.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Quantity',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _AddToCartTheme.textSecondary,
                ),
              ),
              const Spacer(),
              CartQuantitySelector(
                quantity: quantity,
                onDecrement: onDecrement ?? () {},
                onIncrement: onIncrement,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (availableSizes.isNotEmpty) ...[
            _SectionTitle(title: 'Select size'),
            const SizedBox(height: 6),
            _SizeSelector(
              sizes: availableSizes,
              selected: selectedSize,
              onSelected: onSizeSelected,
            ),
            if (errorText != null) ...[
              const SizedBox(height: 4),
              Text(
                errorText!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
          const _StockStatusIndicator(),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: ShopTokens.textPrimary,
          ),
    );
  }
}

class _StickyCtaBar extends StatelessWidget {
  const _StickyCtaBar({
    required this.totalPrice,
    required this.onBuyNow,
    required this.onAddToCart,
    required this.addToCartLabel,
    required this.colorScheme,
  });

  final double totalPrice;
  final VoidCallback onBuyNow;
  final VoidCallback? onAddToCart;
  final String addToCartLabel;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _AddToCartTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    'Rs. ${totalPrice.toStringAsFixed(2)}',
                    key: ValueKey(totalPrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ShopTokens.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onBuyNow,
            child: const Text('Buy now'),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: AddToCartSheetDefaults.primaryButtonHeight,
              child: FilledButton(
                onPressed: onAddToCart,
                style: FilledButton.styleFrom(
                  backgroundColor: _AddToCartTheme.accent,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  addToCartLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeSelector extends StatelessWidget {
  const _SizeSelector({
    required this.sizes,
    required this.selected,
    required this.onSelected,
  });

  final List<String> sizes;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sizes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = sizes[i];
          final isSelected = s == selected;
          return _ChoiceChipButton(
            label: s,
            selected: isSelected,
            onTap: () => onSelected(s),
          );
        },
      ),
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? _AddToCartTheme.midGray : Colors.white;
    final border = selected ? ShopTokens.textPrimary : _AddToCartTheme.borderGray;
    final text = selected ? ShopTokens.textPrimary : _AddToCartTheme.textSecondary;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ),
      ),
    );
  }
}

class _StockStatusIndicator extends StatelessWidget {
  const _StockStatusIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF1B8B4A), size: 16),
          SizedBox(width: 6),
          Text(
            'In stock • Ready to ship',
            style: TextStyle(
              color: Color(0xFF1B8B4A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.length, required this.activeIndex});

  final int length;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            height: 6,
            width: i == activeIndex ? 16 : 6,
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? ShopTokens.textPrimary
                  : Colors.black.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AddToCartTheme.softGray,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: AddToCartSheetDefaults.headerIconSize,
            color: _AddToCartTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

