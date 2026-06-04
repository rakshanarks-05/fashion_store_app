import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../cart/presentation/providers/cart_providers.dart';
import '../../cart/presentation/providers/cart_ui_providers.dart';
import '../../cart/presentation/utils/cart_formatters.dart';
import '../../order/data/services/order_service.dart';
import '../../order/domain/entities/order_model.dart';
import '../presentation/providers/checkout_providers.dart';

/// Display name derived from the signed-in email (matches checkout UI).
String checkoutNameFromEmail(String? email) {
  if (email == null || email.trim().isEmpty) return 'Customer';
  final local = email.split('@').first.trim();
  return local.isEmpty ? 'Customer' : local;
}

double _checkoutDeliveryFee(CheckoutShippingOption option) {
  return option == CheckoutShippingOption.express ? 500 : 0;
}

/// Grand total from the same inputs as [PaymentMethodScreen] / [CheckoutPage].
double computeCheckoutGrandTotal(Ref ref) {
  final lines = ref.read(cartResolvedLinesProvider);
  final shippingOption = ref.read(checkoutShippingOptionProvider);
  final voucherDiscount = ref.read(checkoutVoucherDiscountProvider);
  final subtotal = computeCartOrderTotal(lines);
  final deliveryFee = _checkoutDeliveryFee(shippingOption);
  final voucher = voucherDiscount.clamp(0, subtotal + deliveryFee).toDouble();
  final fivePctOn = ref.read(checkoutFivePercentPromoEnabledProvider);
  final fivePct = fivePctOn ? (subtotal * 0.05).roundToDouble() : 0.0;
  return (subtotal + deliveryFee - voucher - fivePct)
      .clamp(0.0, double.infinity)
      .toDouble();
}

/// Persists the order to Firestore and clears the cart. Call only after payment succeeds.
///
/// [grandTotal] is validated against [computeCheckoutGrandTotal]; the persisted
/// amount uses the computed value so it always matches cart + checkout state.
Future<String> placeOrderAfterSuccessfulPayment({
  required Ref ref,
  required bool isCardPayment,
  required double grandTotal,
}) async {
  final auth = ref.read(authStateProvider).valueOrNull;
  final uid = auth?.id;
  if (uid == null || uid.isEmpty) {
    throw StateError('Not signed in');
  }

  final cartState = ref.read(cartNotifierProvider);
  if (cartState.items.isEmpty) {
    throw StateError('Cart is empty');
  }

  final lines = ref.read(cartResolvedLinesProvider);
  if (lines.isEmpty) {
    throw StateError('Cart is empty');
  }

  for (final line in lines) {
    if (line.product == null) {
      throw StateError('Product data not loaded for cart item ${line.productId}');
    }
  }

  final computedTotal = computeCheckoutGrandTotal(ref);
  if ((computedTotal - grandTotal).abs() > 0.01) {
    developer.log(
      'placeOrderAfterSuccessfulPayment: total mismatch '
      '(passed $grandTotal, computed $computedTotal) — using computed total.',
      name: 'place_order',
    );
  }

  final items = lines.map((line) {
    final p = line.product!;
    return OrderLineItemModel(
      productId: p.id,
      productName: p.name,
      quantity: line.cartItem.quantity,
      price: p.price,
      imageUrl: p.imageUrl,
    );
  }).toList();

  final paymentMethod = isCardPayment ? 'Card' : 'Cash on Delivery';
  final paymentStatus = isCardPayment ? 'Paid' : 'Pending';

  final name = checkoutNameFromEmail(auth?.email);
  final address = ref.read(resolvedCartShippingAddressProvider);
  final phone = ref.read(checkoutContactPhoneProvider);

  final shipping = OrderShippingAddressModel(
    name: name,
    phone: phone,
    addressLine: address,
    city: '',
    postalCode: '',
  );

  final now = DateTime.now();
  final order = OrderModel(
    orderId: '',
    userId: uid,
    items: items,
    totalAmount: computedTotal,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    orderStatus: 'Placed',
    shippingAddress: shipping,
    createdAt: now,
    updatedAt: now,
  );

  final orderService = OrderService(ref.read(firebaseFirestoreProvider));
  final orderId = await orderService.createOrder(order);

  await ref.read(cartNotifierProvider.notifier).clear();
  return orderId;
}
