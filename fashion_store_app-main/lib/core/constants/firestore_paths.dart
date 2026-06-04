/// Firestore collection ids and user document paths.
abstract final class FirestorePaths {
  static const String products = 'products';
  static const String categories = 'categories';
  static const String collections = 'collections';
  static const String orders = 'orders';
  static const String users = 'users';
  static const String cart = 'cart';
  static const String wishlist = 'wishlist';

  /// Document path: `users/{uid}`.
  static String userDoc(String uid) => '$users/$uid';
}
