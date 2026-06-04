import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';

/// Product admin helpers (e.g. delete from catalog lists).
///
/// Creates go through [FirestoreCreateService] (Admin) with Cloudinary.
class FirestoreService {
  FirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestorePaths.products);

  /// Removes the Firestore document only (does not delete the Cloudinary asset).
  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  /// Live stream of all products (same collection as the shop); prefer
  /// [productListProvider] in UI when Riverpod is available.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchProductsRaw() {
    return _products.snapshots();
  }
}
