import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/order_model.dart';

/// Firestore access for the `orders` collection (writes + reads).
///
/// Uses [FirebaseFirestore.instance] via constructor injection for tests.
class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestorePaths.orders);

  /// Persists a new order; returns the generated document id ([orderId]).
  Future<String> createOrder(OrderModel order) async {
    final doc = _orders.doc();
    final id = doc.id;
    try {
      await doc.set({
        'orderId': id,
        'userId': order.userId,
        'items': order.items.map((e) => e.toJson()).toList(),
        'totalAmount': order.totalAmount,
        'paymentMethod': order.paymentMethod,
        'paymentStatus': order.paymentStatus,
        'orderStatus': order.orderStatus,
        'shippingAddress': order.shippingAddress.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return id;
    } catch (e, st) {
      developer.log(
        'OrderService.createOrder failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Real-time orders for [userId], newest first.
  ///
  /// Uses only `where('userId')` so no composite index is required; results are
  /// sorted by [OrderModel.createdAt] in memory (fine for typical per-user volume).
  Stream<List<OrderModel>> watchUserOrdersStream(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) {
            final list = snapshot.docs
                .map((d) => OrderModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
        );
  }

  /// Orders for a user, newest first (sorted client-side; no composite index).
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final snapshot = await _orders
          .where('userId', isEqualTo: userId)
          .get();
      final list = snapshot.docs
          .map((d) => OrderModel.fromJson(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e, st) {
      developer.log(
        'OrderService.getUserOrders failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Updates [orderStatus] (and bumps `updatedAt`).
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _orders.doc(orderId).update({
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      developer.log(
        'OrderService.updateOrderStatus failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetches one order by id, or `null` if missing or not readable.
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final snap = await _orders.doc(orderId).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return OrderModel.fromJson(data, snap.id);
    } catch (e, st) {
      developer.log(
        'OrderService.getOrderById failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
