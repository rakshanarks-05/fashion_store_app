import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standard (5–7 days, free) vs Express (1–2 days, paid).
enum CheckoutShippingOption {
  standard,
  express,
}

/// Card vs cash on delivery.
enum CheckoutPaymentMethod {
  card,
  cashOnDelivery,
}

final checkoutShippingOptionProvider =
    StateProvider<CheckoutShippingOption>((ref) {
  return CheckoutShippingOption.standard;
});

final checkoutPaymentMethodProvider =
    StateProvider<CheckoutPaymentMethod>((ref) {
  return CheckoutPaymentMethod.card;
});

/// Session phone shown on the contact card (editable).
final checkoutContactPhoneProvider = StateProvider<String>((ref) {
  return '+94 77 123 4567';
});

/// Optional voucher discount in LKR (whole units).
final checkoutVoucherDiscountProvider = StateProvider<double>((ref) {
  return 0;
});

/// Dismissible 5% subtotal promo — shared by checkout and payment so totals
/// and Pay amounts always match (avoids e.g. Rs. 20 on checkout vs Rs. 19 on pay).
final checkoutFivePercentPromoEnabledProvider = StateProvider<bool>((ref) {
  return true;
});
