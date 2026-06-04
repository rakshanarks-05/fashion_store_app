import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cart/presentation/providers/cart_providers.dart';
import '../../../../cart/presentation/providers/cart_ui_providers.dart';
import '../../../../cart/presentation/utils/cart_formatters.dart';
import '../../../../payment/presentation/screens/payment/payment_method_screen.dart';
import '../../../../product/presentation/providers/product_providers.dart';
import '../../../../product/presentation/widgets/shop_bottom_navigation_bar.dart';
import '../../providers/checkout_providers.dart';
import '../../theme/checkout_tokens.dart';
import '../../widgets/address_card_widget.dart';
import '../../widgets/contact_info_card_widget.dart';
import '../../widgets/order_item_widget.dart';
import '../../widgets/payment_method_widget.dart';
import '../../widgets/price_summary_widget.dart';
import '../../widgets/shipping_options_widget.dart';

/// Payment / checkout flow — cart data from existing Riverpod providers.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  static const int _navCartIndex = 3;
  bool _emptyExitScheduled = false;
  bool _signedOutExitScheduled = false;
  bool _authErrorExitScheduled = false;
  bool _payBusy = false;

  final ScrollController _bodyScrollController = ScrollController();

  @override
  void dispose() {
    _bodyScrollController.dispose();
    super.dispose();
  }

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

  String _nameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) return 'Customer';
    final local = email.split('@').first.trim();
    return local.isEmpty ? 'Customer' : local;
  }

  String _deliveryEta(DateTime now, CheckoutShippingOption option) {
    final addDays = option == CheckoutShippingOption.standard ? 7 : 2;
    final d = now.add(Duration(days: addDays));
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final w = weekdays[d.weekday - 1];
    final m = months[d.month - 1];
    return 'Delivered on or before $w, ${d.day} $m ${d.year}';
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
    final emailCtrl = TextEditingController(text: email);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contact information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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

  Future<void> _pickPaymentMethod(CheckoutPaymentMethod current) async {
    final result = await showModalBottomSheet<CheckoutPaymentMethod>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final primary = Theme.of(context).colorScheme.primary;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Payment method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...CheckoutPaymentMethod.values.map((m) {
                  final label = m == CheckoutPaymentMethod.card
                      ? 'Card Payment'
                      : 'Cash on Delivery';
                  final selected = m == current;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? primary : const Color(0xFFBBBBBB),
                    ),
                    onTap: () => Navigator.pop(context, m),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      ref.read(checkoutPaymentMethodProvider.notifier).state = result;
    }
  }

  Future<void> _applyVoucher(double subtotal) async {
    final codeCtrl = TextEditingController();
    final applied = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add voucher'),
          content: TextField(
            controller: codeCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Promo code',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
    if (applied == true && mounted) {
      final code = codeCtrl.text.trim().toUpperCase();
      if (code == 'SAVE10') {
        final disc = (subtotal * 0.1).roundToDouble();
        ref.read(checkoutVoucherDiscountProvider.notifier).state = disc;
        _snack('Voucher applied.');
      } else if (code.isNotEmpty) {
        _snack('Invalid voucher code.');
      }
    }
  }

  Future<void> _onPay() async {
    if (_payBusy) return;
    setState(() => _payBusy = true);
    try {
      final address = ref.read(resolvedCartShippingAddressProvider);
      if (address.trim().isEmpty) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Shipping address required'),
            content: const Text(
              'Add a shipping address on this screen before continuing to payment.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final cartItems = ref.read(cartNotifierProvider).items;
      if (cartItems.isEmpty) {
        _snack('Your cart is empty.');
        return;
      }

      var subtotal = computeCartOrderTotal(ref.read(cartResolvedLinesProvider));

      // While the product stream is still loading, resolved lines have no prices
      // and subtotal is 0 — wait once so the first Pay tap can navigate.
      if (subtotal <= 0 && cartItems.isNotEmpty) {
        final catalog = ref.read(productListProvider);
        if (catalog.hasError) {
          _snack(
            'Could not load product prices. Check your connection and try again.',
          );
          return;
        }
        if (catalog.isLoading) {
          try {
            await ref.read(productListProvider.future);
          } catch (_) {
            if (mounted) {
              _snack(
                'Could not load product prices. Check your connection and try again.',
              );
            }
            return;
          }
          if (!mounted) return;
          subtotal = computeCartOrderTotal(ref.read(cartResolvedLinesProvider));
        }
      }

      if (subtotal <= 0 && cartItems.isNotEmpty) {
        _snack('Unable to compute order total.');
        return;
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/payment'),
          builder: (context) => const PaymentMethodScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _payBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);
    final lines = ref.watch(cartResolvedLinesProvider);
    final categoryMap =
        ref.watch(categoryIdToNameProvider).valueOrNull ?? const {};
    final shipping = ref.watch(resolvedCartShippingAddressProvider);
    final phone = ref.watch(checkoutContactPhoneProvider);
    final shippingOption = ref.watch(checkoutShippingOptionProvider);
    final paymentMethod = ref.watch(checkoutPaymentMethodProvider);
    final voucherDiscount = ref.watch(checkoutVoucherDiscountProvider);
    final fivePercentPromoOn = ref.watch(
      checkoutFivePercentPromoEnabledProvider,
    );

    final auth = ref.watch(authStateProvider);

    if (auth.isLoading) {
      return Theme(
        data: Theme.of(
          context,
        ).copyWith(scaffoldBackgroundColor: CheckoutTokens.background),
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (auth.hasError) {
      if (!_authErrorExitScheduled) {
        _authErrorExitScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _snack('We could not verify your account. Check your connection and try again.');
          Navigator.of(context).pop();
        });
      }
      return Theme(
        data: Theme.of(
          context,
        ).copyWith(scaffoldBackgroundColor: CheckoutTokens.background),
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (auth.valueOrNull == null) {
      if (!_signedOutExitScheduled) {
        _signedOutExitScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _snack('Sign in to complete checkout.');
          Navigator.of(context).pop();
        });
      }
      return Theme(
        data: Theme.of(
          context,
        ).copyWith(scaffoldBackgroundColor: CheckoutTokens.background),
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final email = auth.valueOrNull?.email ?? '';

    final subtotal = computeCartOrderTotal(lines);
    final deliveryFee = _deliveryFee(shippingOption);
    final discount = voucherDiscount
        .clamp(0, subtotal + deliveryFee)
        .toDouble();
    final fivePercentDiscount = fivePercentPromoOn
        ? (subtotal * 0.05).roundToDouble()
        : 0.0;
    final grandTotal = (subtotal + deliveryFee - discount - fivePercentDiscount)
        .clamp(0.0, double.infinity)
        .toDouble();

    final eta = _deliveryEta(DateTime.now(), shippingOption);

    if (!cart.loading && cart.items.isEmpty) {
      if (!_emptyExitScheduled) {
        _emptyExitScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _snack('Your cart is empty.');
          Navigator.of(context).pop();
        });
      }
      return Theme(
        data: Theme.of(
          context,
        ).copyWith(scaffoldBackgroundColor: CheckoutTokens.background),
        child: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: CheckoutTokens.background,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: CheckoutTokens.textPrimary,
          displayColor: CheckoutTokens.textPrimary,
        ),
      ),
      child: Scaffold(
        backgroundColor: CheckoutTokens.background,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CheckoutPayBar(total: grandTotal, isBusy: _payBusy, onPay: _onPay),
            ShopHomeBottomNavigationBar(
              currentIndex: _navCartIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            primary: false,
            controller: _bodyScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    8,
                    CheckoutTokens.horizontalPadding,
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
                          color: CheckoutTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: CheckoutTokens.screenTitle,
                          fontWeight: FontWeight.w800,
                          color: CheckoutTokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    20,
                    CheckoutTokens.horizontalPadding,
                    0,
                  ),
                  child: AddressCardWidget(
                    fullName: _nameFromEmail(email),
                    address: shippingAddressDisplayLabel(shipping),
                    onEdit: () => _editAddress(shipping),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    16,
                    CheckoutTokens.horizontalPadding,
                    0,
                  ),
                  child: ContactInfoCardWidget(
                    phone: phone,
                    email: email.isEmpty ? '—' : email,
                    onEdit: () => _editContact(phone, email),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    CheckoutTokens.sectionGap,
                    CheckoutTokens.horizontalPadding,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: CheckoutTokens.sectionTitle,
                          fontWeight: FontWeight.w700,
                          color: CheckoutTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CheckoutTokens.badgeFill,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.items.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: CheckoutTokens.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => _applyVoucher(subtotal),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Add Voucher',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (fivePercentPromoOn) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CheckoutTokens.pillBackground,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                                    color: Theme.of(context).colorScheme.primary,
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
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    16,
                    CheckoutTokens.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      if (cart.loading && cart.items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        for (var i = 0; i < lines.length; i++)
                          OrderItemWidget(
                            line: lines[i],
                            subtitle: productCartSubtitle(
                              lines[i].product,
                              lines[i].product == null
                                  ? null
                                  : categoryMap[lines[i].product!.categoryId],
                              selectedSize: lines[i].cartItem.selectedSize,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    8,
                    CheckoutTokens.horizontalPadding,
                    0,
                  ),
                  child: ShippingOptionsWidget(
                    option: shippingOption,
                    onChanged: (o) =>
                        ref
                                .read(checkoutShippingOptionProvider.notifier)
                                .state =
                            o,
                    etaLine: eta,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    CheckoutTokens.sectionGap,
                    CheckoutTokens.horizontalPadding,
                    0,
                  ),
                  child: PaymentMethodWidget(
                    method: paymentMethod,
                    showInlineOptions: false,
                    onEdit: () => _pickPaymentMethod(paymentMethod),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CheckoutTokens.horizontalPadding,
                    CheckoutTokens.sectionGap,
                    CheckoutTokens.horizontalPadding,
                    32,
                  ),
                  child: PriceSummaryWidget(
                    subtotal: subtotal,
                    deliveryFee: deliveryFee,
                    discount: discount,
                    fivePercentDiscount: fivePercentDiscount,
                    total: grandTotal,
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

class _CheckoutPayBar extends StatelessWidget {
  const _CheckoutPayBar({
    required this.total,
    required this.onPay,
    this.isBusy = false,
  });

  final double total;
  final Future<void> Function() onPay;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CheckoutTokens.background,
      elevation: 0,
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
                      color: CheckoutTokens.textPrimary,
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
                  onPressed: isBusy ? null : () => onPay(),
                  style: FilledButton.styleFrom(
                    backgroundColor: CheckoutTokens.payButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        CheckoutTokens.buttonRadius,
                      ),
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
