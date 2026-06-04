import 'dart:math';

/// Result of a payment attempt (gateway-agnostic).
class PaymentProcessResult {
  const PaymentProcessResult({
    required this.success,
    this.orderId,
    this.transactionId,
    this.message,
    this.rawPayload,
  });

  final bool success;
  final String? orderId;
  final String? transactionId;
  final String? message;
  final Map<String, dynamic>? rawPayload;
}

/// Card data for a charge (integrate with Stripe / PayHere / Razorpay — no keys here).
class CardPaymentInput {
  const CardPaymentInput({
    required this.cardNumberDigits,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  /// Digits only (no spaces).
  final String cardNumberDigits;
  final String holderName;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;

  String get last4 => cardNumberDigits.length >= 4
      ? cardNumberDigits.substring(cardNumberDigits.length - 4)
      : cardNumberDigits;
}

/// Saved / tokenized card surface for UI + mock processing.
class SavedCardDisplay {
  const SavedCardDisplay({
    required this.last4,
    required this.holderName,
    required this.expiryMmYy,
  });

  final String last4;
  final String holderName;
  final String expiryMmYy;
}

/// Abstraction for real payment gateways (Stripe, PayHere, Razorpay, …).
abstract class PaymentService {
  Future<PaymentProcessResult> processCardPayment({
    required CardPaymentInput input,
    required double amount,
    String currencyCode = 'LKR',
  });

  Future<PaymentProcessResult> processSavedCard({
    required SavedCardDisplay card,
    required double amount,
    String currencyCode = 'LKR',
  });

  Future<PaymentProcessResult> processCashOnDelivery({
    required double amount,
    String currencyCode = 'LKR',
  });

  /// Map gateway webhook / SDK callback JSON to a normalized result.
  PaymentProcessResult handlePaymentResponse(Map<String, dynamic> payload);
}

/// Mock implementation: network delay + success/failure simulation.
/// Replace with a concrete adapter per provider in production.
class MockPaymentService implements PaymentService {
  MockPaymentService({this.simulateFailure = false, Random? random})
      : _random = random ?? Random();

  /// When true, [processCardPayment] / [processSavedCard] return failure (for QA).
  bool simulateFailure;
  final Random _random;

  Duration get _latency =>
      Duration(milliseconds: 1500 + _random.nextInt(800));

  @override
  Future<PaymentProcessResult> processCardPayment({
    required CardPaymentInput input,
    required double amount,
    String currencyCode = 'LKR',
  }) async {
    await Future<void>.delayed(_latency);
    if (simulateFailure) {
      return PaymentProcessResult(
        success: false,
        message: 'Payment declined',
        rawPayload: {'mock': true, 'method': 'card', 'currency': currencyCode},
      );
    }
    final id = _orderId();
    return PaymentProcessResult(
      success: true,
      orderId: id,
      transactionId: 'TXN-${_random.nextInt(999999)}',
      message: 'Paid',
      rawPayload: {'mock': true, 'amount': amount, 'currency': currencyCode},
    );
  }

  @override
  Future<PaymentProcessResult> processSavedCard({
    required SavedCardDisplay card,
    required double amount,
    String currencyCode = 'LKR',
  }) async {
    await Future<void>.delayed(_latency);
    if (simulateFailure) {
      return PaymentProcessResult(
        success: false,
        message: 'Payment declined',
        rawPayload: {'mock': true, 'method': 'saved_card'},
      );
    }
    final id = _orderId();
    return PaymentProcessResult(
      success: true,
      orderId: id,
      transactionId: 'TXN-${_random.nextInt(999999)}',
      message: 'Paid',
      rawPayload: {
        'mock': true,
        'last4': card.last4,
        'amount': amount,
        'currency': currencyCode,
      },
    );
  }

  @override
  Future<PaymentProcessResult> processCashOnDelivery({
    required double amount,
    String currencyCode = 'LKR',
  }) async {
    await Future<void>.delayed(_latency);
    if (simulateFailure) {
      return PaymentProcessResult(
        success: false,
        message: 'Could not place COD order',
        rawPayload: {'mock': true, 'method': 'cod'},
      );
    }
    return PaymentProcessResult(
      success: true,
      orderId: _orderId(),
      message: 'Order placed (COD)',
      rawPayload: {'mock': true, 'amount': amount, 'currency': currencyCode},
    );
  }

  @override
  PaymentProcessResult handlePaymentResponse(Map<String, dynamic> payload) {
    final ok = payload['success'] == true || payload['status'] == 'succeeded';
    return PaymentProcessResult(
      success: ok,
      orderId: payload['orderId'] as String?,
      transactionId: payload['transactionId'] as String?,
      message: payload['message'] as String?,
      rawPayload: payload,
    );
  }

  String _orderId() =>
      'ORD-${DateTime.now().millisecondsSinceEpoch % 100000000}';
}
