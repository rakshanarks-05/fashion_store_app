import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cart/presentation/providers/cart_providers.dart';
import '../../../../cart/presentation/providers/cart_ui_providers.dart';
import '../../../../cart/presentation/utils/cart_formatters.dart';
import '../../../../checkout/presentation/providers/checkout_providers.dart';
import '../../../../order/presentation/providers/order_providers.dart';
import '../../../../checkout/presentation/widgets/address_card_widget.dart';
import '../../../../checkout/presentation/widgets/contact_info_card_widget.dart';
import '../../../../checkout/presentation/widgets/order_item_widget.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../../product/presentation/providers/product_providers.dart';
import '../../../../product/presentation/widgets/shop_bottom_navigation_bar.dart';
import '../../../services/payment_service.dart';
import '../../providers/payment_providers.dart';
import '../../theme/payment_tokens.dart';
import '../../widgets/payment_option_tile.dart';
import '../../widgets/saved_payment_card_widget.dart';
import 'card_payment_screen.dart';
import 'payment_failure_screen.dart';
import 'payment_processing_screen.dart';

enum _PaySelection { card, cod }

/// Step between [CheckoutPage] and payment success: review address, items,
/// choose **card** (saved card + add new) or **cash on delivery**, then Pay.
class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  static const int _navCartIndex = 3;

  bool _isSubmitting = false;

  /// Own controller so this route does not inherit [PrimaryScrollController] from below.
  final ScrollController _bodyScrollController = ScrollController();

  @override
  void dispose() {
    _bodyScrollController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  _PaySelection _selection = _PaySelection.card;

  SavedCardDisplay _savedCard = const SavedCardDisplay(
    last4: '1579',
    holderName: '',
    expiryMmYy: '12/28',
  );

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

  String _nameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) return 'Customer';
    final local = email.split('@').first.trim();
    return local.isEmpty ? 'Customer' : local;
  }

  String _resolvedCardHolderName({
    required String email,
    String? profileDisplayName,
  }) {
    final current = _savedCard.holderName.trim();
    if (current.isNotEmpty) return current;
    final fromProfile = profileDisplayName?.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    return _nameFromEmail(email);
  }

  double _deliveryFee(CheckoutShippingOption option) {
    return option == CheckoutShippingOption.express ? 500 : 0;
  }

  Future<void> _editAddress(String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Shipping address'),
          content: TextField(
            controller: controller,
            maxLines: 4,
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

  Future<void> _editContact(String phone, String email) async {
    final phoneCtrl = TextEditingController(text: phone);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contact information'),
          content: TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result == true && mounted) {
      ref.read(checkoutContactPhoneProvider.notifier).state = phoneCtrl.text
          .trim();
    }
  }

  Future<void> _openAddCard() async {
    final result = await Navigator.of(context).push<SavedCardDisplay>(
      MaterialPageRoute(builder: (context) => const CardPaymentScreen()),
    );
    if (result != null && mounted) {
      setState(() => _savedCard = result);
    }
  }

  Future<void> _openCardSettings({
    required String email,
    String? profileDisplayName,
  }) async {
    final initial = SavedCardDisplay(
      last4: _savedCard.last4,
      holderName: _resolvedCardHolderName(
        email: email,
        profileDisplayName: profileDisplayName,
      ),
      expiryMmYy: _savedCard.expiryMmYy,
    );
    final result = await Navigator.of(context).push<SavedCardDisplay>(
      MaterialPageRoute(
        builder: (context) => CardPaymentScreen(initialCard: initial),
      ),
    );
    if (result != null && mounted) {
      setState(() => _savedCard = result);
    }
  }

  double _computeGrandTotal() {
    final lines = ref.read(cartResolvedLinesProvider);
    final shippingOption = ref.read(checkoutShippingOptionProvider);
    final voucherDiscount = ref.read(checkoutVoucherDiscountProvider);
    final subtotal = computeCartOrderTotal(lines);
    final deliveryFee = _deliveryFee(shippingOption);
    final voucher = voucherDiscount.clamp(0, subtotal + deliveryFee).toDouble();
    final fivePctOn = ref.read(checkoutFivePercentPromoEnabledProvider);
    final fivePct = fivePctOn ? (subtotal * 0.05).roundToDouble() : 0.0;
    return (subtotal + deliveryFee - voucher - fivePct)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  Future<void> _runPayment() async {
    if (_isSubmitting) return;
    final amount = _computeGrandTotal();
    final authUser = ref.read(authStateProvider).valueOrNull;
    final profile = ref.read(userProfileProvider).valueOrNull;
    final effectiveCard = SavedCardDisplay(
      last4: _savedCard.last4,
      holderName: _resolvedCardHolderName(
        email: authUser?.email ?? '',
        profileDisplayName: profile?.displayName,
      ),
      expiryMmYy: _savedCard.expiryMmYy,
    );
    setState(() => _isSubmitting = true);
    ref.read(orderPlacementProvider.notifier).reset();

    showPaymentProcessingDialog(context);
    final service = ref.read(paymentServiceProvider);

    PaymentProcessResult result;
    try {
      if (_selection == _PaySelection.cod) {
        result = await service.processCashOnDelivery(amount: amount);
      } else {
        result = await service.processSavedCard(
          card: effectiveCard,
          amount: amount,
        );
      }
    } catch (e, st) {
      developer.log('Payment failed', error: e, stackTrace: st);
      result = PaymentProcessResult(success: false, message: e.toString());
    }

    if (!mounted) return;

    if (!result.success) {
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isSubmitting = false);
      await showPaymentFailureDialog(
        context,
        message: result.message ?? 'Payment could not be completed.',
        onRetry: () {
          Navigator.of(context, rootNavigator: true).pop();
          _runPayment();
        },
        onClose: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      );
      return;
    }

    // Payment succeeded — persist order to Firestore while the overlay stays up.
    String? firestoreOrderId;
    try {
      firestoreOrderId = await ref
          .read(orderPlacementProvider.notifier)
          .completeAfterPayment(
            isCardPayment: _selection == _PaySelection.card,
            grandTotal: amount,
          );
      ref.invalidate(ordersForUserProvider);
    } catch (e, st) {
      developer.log('Order save failed', error: e, stackTrace: st);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isSubmitting = false);
      _snack(
        'Payment went through but we could not save your order. Please contact support.',
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order confirmed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    final nav = Navigator.of(context);
    var foundCart = false;
    nav.popUntil((route) {
      final isCart = route.settings.name == '/cart';
      foundCart = foundCart || isCart;
      return isCart;
    });
    if (!foundCart) {
      nav.pushNamedAndRemoveUntil('/cart', (route) => false);
    }
  }

  Widget _blockedPaymentView({required String title, required String message}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: PaymentTokens.pageBackgroundTop,
      appBar: AppBar(
        backgroundColor: PaymentTokens.pageBackgroundTop,
        elevation: 0,
        foregroundColor: PaymentTokens.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: PaymentTokens.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payment_outlined,
                size: 56,
                color: PaymentTokens.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: PaymentTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final auth = ref.watch(authStateProvider);

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: PaymentTokens.pageBackgroundTop,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.hasError) {
      return _blockedPaymentView(
        title: 'Payment',
        message:
            'We could not verify your account. Check your connection and try again.',
      );
    }

    if (auth.valueOrNull == null) {
      return _blockedPaymentView(
        title: 'Payment',
        message: 'Sign in to complete payment.',
      );
    }

    final cart = ref.watch(cartNotifierProvider);
    if (!cart.loading && cart.items.isEmpty) {
      return _blockedPaymentView(
        title: 'Payment',
        message: 'Your cart is empty. Add items before paying.',
      );
    }

    final lines = ref.watch(cartResolvedLinesProvider);
    final categoryMap =
        ref.watch(categoryIdToNameProvider).valueOrNull ?? const {};
    final shipping = ref.watch(resolvedCartShippingAddressProvider);
    final phone = ref.watch(checkoutContactPhoneProvider);
    final shippingOption = ref.watch(checkoutShippingOptionProvider);
    final voucherDiscount = ref.watch(checkoutVoucherDiscountProvider);
    final fivePercentPromoOn = ref.watch(
      checkoutFivePercentPromoEnabledProvider,
    );
    final profile = ref.watch(userProfileProvider).valueOrNull;

    final email = auth.valueOrNull?.email ?? '';
    final cardHolderName = _resolvedCardHolderName(
      email: email,
      profileDisplayName: profile?.displayName,
    );

    final subtotal = computeCartOrderTotal(lines);
    final deliveryFee = _deliveryFee(shippingOption);
    final voucher = voucherDiscount.clamp(0, subtotal + deliveryFee).toDouble();
    final fivePct = fivePercentPromoOn
        ? (subtotal * 0.05).roundToDouble()
        : 0.0;
    final grandTotal = (subtotal + deliveryFee - voucher - fivePct)
        .clamp(0.0, double.infinity)
        .toDouble();

    final masked = '* * * *   * * * *   * * * *   ${_savedCard.last4}';
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: PaymentTokens.pageBackgroundTop,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PaymentPayBar(
            total: grandTotal,
            isBusy: _isSubmitting,
            onPay: () {
              if (shipping.trim().isEmpty) {
                _snack(
                  'Add a shipping address before paying. Use back to edit checkout.',
                );
                return;
              }
              _runPayment();
            },
          ),
          ShopHomeBottomNavigationBar(
            currentIndex: _navCartIndex,
            onTap: _onNavTap,
            showCartNotificationDot: true,
          ),
        ],
      ),
      body: ColoredBox(
        color: PaymentTokens.pageBackgroundTop,
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Material(
                  color: PaymentTokens.pageBackgroundTop,
                  child: SingleChildScrollView(
                    controller: _bodyScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PaymentTokens.horizontalPadding,
                            8,
                            PaymentTokens.horizontalPadding,
                            0,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: PaymentTokens.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: PaymentTokens.titleSize,
                                  fontWeight: FontWeight.w800,
                                  color: PaymentTokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PaymentTokens.horizontalPadding,
                            20,
                            PaymentTokens.horizontalPadding,
                            0,
                          ),
                          child: AddressCardWidget(
                            fullName: _nameFromEmail(email),
                            address: shippingAddressDisplayLabel(shipping),
                            backgroundColor: PaymentTokens.shippingCardFill,
                            boxShadow: const [],
                            editButtonColor: primary,
                            onEdit: () => _editAddress(shipping),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PaymentTokens.horizontalPadding,
                            14,
                            PaymentTokens.horizontalPadding,
                            0,
                          ),
                          child: ContactInfoCardWidget(
                            phone: phone,
                            email: email.isEmpty ? '—' : email,
                            backgroundColor: PaymentTokens.shippingCardFill,
                            boxShadow: const [],
                            editButtonColor: primary,
                            onEdit: () => _editContact(phone, email),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PaymentTokens.horizontalPadding,
                            22,
                            PaymentTokens.horizontalPadding,
                            0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: PaymentTokens.sectionTitle,
                                  fontWeight: FontWeight.w700,
                                  color: PaymentTokens.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0E4EB),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${cart.items.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: PaymentTokens.textPrimary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (fivePercentPromoOn)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PaymentTokens.discountPillFill,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '5% Discount',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () =>
                                            ref
                                                    .read(
                                                      checkoutFivePercentPromoEnabledProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                false,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PaymentTokens.horizontalPadding,
                            14,
                            PaymentTokens.horizontalPadding,
                            0,
                          ),
                          child: Column(
                            children: [
                              if (cart.loading && cart.items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                for (var i = 0; i < lines.length; i++)
                                  OrderItemWidget(
                                    line: lines[i],
                                    subtitle: productCartSubtitle(
                                      lines[i].product,
                                      lines[i].product == null
                                          ? null
                                          : categoryMap[lines[i]
                                                .product!
                                                .categoryId],
                                      selectedSize: lines[i].cartItem.selectedSize,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          color: PaymentTokens.sectionWhite,
                          padding: const EdgeInsets.fromLTRB(
                            PaymentTokens.horizontalPadding,
                            20,
                            PaymentTokens.horizontalPadding,
                            28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Methods',
                                style: TextStyle(
                                  fontSize: PaymentTokens.sectionTitle,
                                  fontWeight: FontWeight.w800,
                                  color: PaymentTokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_selection == _PaySelection.card) ...[
                                SavedPaymentCardWidget(
                                  maskedNumberLine: masked,
                                  holderName: cardHolderName,
                                  expiryMmYy: _savedCard.expiryMmYy,
                                  onSettings: () => _openCardSettings(
                                    email: email,
                                    profileDisplayName: profile?.displayName,
                                  ),
                                  onAddTap: _openAddCard,
                                ),
                                const SizedBox(height: 16),
                              ],
                              PaymentOptionTile(
                                title: 'Credit / Debit Card',
                                selected: _selection == _PaySelection.card,
                                leading: const Icon(
                                  Icons.credit_card_outlined,
                                  size: 22,
                                  color: PaymentTokens.textPrimary,
                                ),
                                onTap: () => setState(
                                  () => _selection = _PaySelection.card,
                                ),
                              ),
                              const SizedBox(height: 10),
                              PaymentOptionTile(
                                title: 'Cash on Delivery',
                                selected: _selection == _PaySelection.cod,
                                leading: const Icon(
                                  Icons.payments_outlined,
                                  size: 22,
                                  color: PaymentTokens.textPrimary,
                                ),
                                onTap: () => setState(
                                  () => _selection = _PaySelection.cod,
                                ),
                              ),
                              if (_selection == _PaySelection.cod) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'You will pay when your order is delivered.',
                                  style: TextStyle(
                                    fontSize: PaymentTokens.body,
                                    height: 1.35,
                                    color: PaymentTokens.textSecondary
                                        .withValues(alpha: 0.95),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentPayBar extends StatelessWidget {
  const _PaymentPayBar({
    required this.total,
    required this.onPay,
    required this.isBusy,
  });

  final double total;
  final VoidCallback onPay;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final enabled = !isBusy;
    final bg = enabled ? const Color(0xFF1A1A1A) : PaymentTokens.payDisabled;
    return Material(
      color: PaymentTokens.pageBackgroundTop,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: PaymentTokens.textPrimary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Total ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: formatLkr(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: enabled ? onPay : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: bg,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: PaymentTokens.payDisabled,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Pay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
