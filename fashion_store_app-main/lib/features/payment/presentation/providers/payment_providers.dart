import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/payment_service.dart';

/// Injectable payment gateway (swap [MockPaymentService] for Stripe/PayHere/Razorpay).
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return MockPaymentService(simulateFailure: ref.watch(paymentSimulateFailureProvider));
});

/// Dev/QA: when true, mock payments fail.
final paymentSimulateFailureProvider = StateProvider<bool>((ref) => false);
