import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../checkout/domain/place_order.dart';

/// UI-facing phases for Firestore order creation after payment.
enum OrderPlacementPhase {
  idle,
  placing,
  success,
  failed,
}

class OrderPlacementState extends Equatable {
  const OrderPlacementState({
    this.phase = OrderPlacementPhase.idle,
    this.lastOrderId,
    this.errorMessage,
  });

  final OrderPlacementPhase phase;
  final String? lastOrderId;
  final String? errorMessage;

  OrderPlacementState copyWith({
    OrderPlacementPhase? phase,
    String? lastOrderId,
    String? errorMessage,
    bool clearOrderId = false,
    bool clearError = false,
  }) {
    return OrderPlacementState(
      phase: phase ?? this.phase,
      lastOrderId: clearOrderId ? null : (lastOrderId ?? this.lastOrderId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [phase, lastOrderId, errorMessage];
}

/// Tracks Firestore order submission after a successful payment attempt.
class OrderPlacementNotifier extends StateNotifier<OrderPlacementState> {
  OrderPlacementNotifier(this.ref) : super(const OrderPlacementState());

  final Ref ref;

  void reset() {
    state = const OrderPlacementState();
  }

  /// Persists the order and clears the cart. Returns Firestore order id.
  Future<String> completeAfterPayment({
    required bool isCardPayment,
    required double grandTotal,
  }) async {
    state = state.copyWith(
      phase: OrderPlacementPhase.placing,
      clearError: true,
      clearOrderId: true,
    );
    try {
      final id = await placeOrderAfterSuccessfulPayment(
        ref: ref,
        isCardPayment: isCardPayment,
        grandTotal: grandTotal,
      );
      state = OrderPlacementState(
        phase: OrderPlacementPhase.success,
        lastOrderId: id,
      );
      return id;
    } catch (e, st) {
      developer.log(
        'Order placement failed',
        error: e,
        stackTrace: st,
        name: 'OrderPlacementNotifier',
      );
      state = OrderPlacementState(
        phase: OrderPlacementPhase.failed,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final orderPlacementProvider =
    StateNotifierProvider<OrderPlacementNotifier, OrderPlacementState>((ref) {
  return OrderPlacementNotifier(ref);
});
