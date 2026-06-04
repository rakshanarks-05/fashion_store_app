import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../models/cart_item_model.dart';

abstract class CartRemoteDataSource {
  Future<void> addItem(
    String userId,
    String productId,
    int quantity, {
    String? selectedSize,
  });
  Future<List<CartItemModel>> fetchItems(String userId);
  Future<void> removeItem(String userId, String productId);
  Future<void> setItemQuantity(String userId, String productId, int quantity);
  Future<void> setItemSelection(
    String userId,
    String productId, {
    required int quantity,
    String? selectedSize,
  });
  Future<void> clearCart(String userId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  CartRemoteDataSourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _cartCol(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.cart);
  }

  @override
  Future<void> addItem(
    String userId,
    String productId,
    int quantity, {
    String? selectedSize,
  }) async {
    final doc = _cartCol(userId).doc(productId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
      final normalizedSize = selectedSize?.trim();
      tx.set(
        doc,
        {
          'productId': productId,
          'quantity': current + quantity,
          if (normalizedSize != null && normalizedSize.isNotEmpty)
            'selectedSize': normalizedSize,
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<List<CartItemModel>> fetchItems(String userId) async {
    final snap = await _cartCol(userId).get();
    return snap.docs
        .map((d) => CartItemModel.fromJson(d.data(), d.id))
        .toList();
  }

  @override
  Future<void> removeItem(String userId, String productId) async {
    await _cartCol(userId).doc(productId).delete();
  }

  @override
  Future<void> setItemQuantity(
    String userId,
    String productId,
    int quantity,
  ) async {
    final doc = _cartCol(userId).doc(productId);
    if (quantity <= 0) {
      await doc.delete();
      return;
    }
    await doc.set(
      {
        'productId': productId,
        'quantity': quantity,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> setItemSelection(
    String userId,
    String productId, {
    required int quantity,
    String? selectedSize,
  }) async {
    final doc = _cartCol(userId).doc(productId);
    if (quantity <= 0) {
      await doc.delete();
      return;
    }
    final normalizedSize = selectedSize?.trim();
    await doc.set(
      {
        'productId': productId,
        'quantity': quantity,
        if (normalizedSize != null && normalizedSize.isNotEmpty)
          'selectedSize': normalizedSize
        else
          'selectedSize': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> clearCart(String userId) async {
    final snap = await _cartCol(userId).get();
    if (snap.docs.isEmpty) return;

    const chunk = 450;
    for (var i = 0; i < snap.docs.length; i += chunk) {
      final batch = _firestore.batch();
      final end = (i + chunk > snap.docs.length) ? snap.docs.length : i + chunk;
      for (var j = i; j < end; j++) {
        batch.delete(snap.docs[j].reference);
      }
      await batch.commit();
    }
  }
}
