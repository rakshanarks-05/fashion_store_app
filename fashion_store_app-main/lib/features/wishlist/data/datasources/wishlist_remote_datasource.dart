import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../models/wishlist_item_model.dart';

abstract class WishlistRemoteDataSource {
  Future<List<WishlistItemModel>> fetchItems(String userId);
  Future<void> addItem(String userId, String productId);
}

class WishlistRemoteDataSourceImpl implements WishlistRemoteDataSource {
  WishlistRemoteDataSourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.wishlist);
  }

  @override
  Future<List<WishlistItemModel>> fetchItems(String userId) async {
    final snap = await _col(userId).get();
    return snap.docs
        .map((d) => WishlistItemModel.fromJson(d.data(), d.id))
        .toList();
  }

  @override
  Future<void> addItem(String userId, String productId) {
    return _col(userId).doc(productId).set({
      'productId': productId,
    }, SetOptions(merge: true));
  }
}
