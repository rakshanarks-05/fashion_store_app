import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/firestore_create/models/category_document.dart';

/// Loads catalog categories from Firestore and applies user-gender visibility rules.
class CategoryService {
  CategoryService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Fetches all documents in [FirestorePaths.categories], maps them to
  /// [CategoryDocument], then keeps only categories visible for [userGender].
  ///
  /// Visible when category `gender` is [userGender] or `"both"`. Missing or
  /// invalid stored values are treated as `"both"` (see [CategoryDocument.fromFirestore]).
  Future<List<CategoryDocument>> fetchCategoriesForUser(String userGender) async {
    final snapshot = await _firestore.collection(FirestorePaths.categories).get();
    final docs = snapshot.docs
        .map((d) => CategoryDocument.fromFirestore(d.data(), d.id))
        .toList();
    docs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return docs.where((c) => _visibleForUser(c.gender, userGender)).toList();
  }

  static bool _visibleForUser(String? categoryGender, String userGender) {
    final c = _normalizeCategoryGender(categoryGender);
    final u = _normalizeUserGender(userGender);
    return c == 'both' || c == u;
  }

  static String _normalizeCategoryGender(String? g) {
    if (g == null || g.isEmpty) return 'both';
    final v = g.trim().toLowerCase();
    if (v == 'male' || v == 'female' || v == 'both') return v;
    return 'both';
  }

  static String _normalizeUserGender(String userGender) {
    final v = userGender.trim().toLowerCase();
    if (v == 'male' || v == 'female') return v;
    return 'female';
  }
}
