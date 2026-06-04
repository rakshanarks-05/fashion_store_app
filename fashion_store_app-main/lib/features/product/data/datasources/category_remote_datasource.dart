import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';

abstract class CategoryRemoteDataSource {
  /// Document id → display name from `categories/{id}`.
  Stream<Map<String, String>> watchCategoryIdToName();

  /// Document id → normalized `gender` from `categories/{id}` (`male`, `female`, `both`, `kids`).
  ///
  /// Missing or invalid values are treated as `both` (unisex). Extended values like
  /// `kid` / `kids` normalize to `kids` for the shop **For** filter.
  Stream<Map<String, String>> watchCategoryIdToGender();
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<Map<String, String>> watchCategoryIdToName() {
    return _firestore.collection(FirestorePaths.categories).snapshots().map(
      (snapshot) {
        final map = <String, String>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final name = (data['name'] as String?)?.trim() ?? '';
          map[doc.id] = name.isNotEmpty ? name : doc.id;
        }
        return map;
      },
    );
  }

  @override
  Stream<Map<String, String>> watchCategoryIdToGender() {
    return _firestore.collection(FirestorePaths.categories).snapshots().map(
      (snapshot) {
        final map = <String, String>{};
        for (final doc in snapshot.docs) {
          map[doc.id] = _normalizeCategoryGenderField(doc.data()['gender']);
        }
        return map;
      },
    );
  }

  /// Aligns with [CategoryDocument] (`male` / `female` / `both`) plus `kids` for child categories.
  static String _normalizeCategoryGenderField(Object? value) {
    if (value == null) return 'both';
    if (value is! String) return 'both';
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return 'both';
    if (v == 'male' || v == 'female' || v == 'both') return v;
    if (v == 'kid' || v == 'kids' || v == 'child' || v == 'children') {
      return 'kids';
    }
    return 'both';
  }
}
