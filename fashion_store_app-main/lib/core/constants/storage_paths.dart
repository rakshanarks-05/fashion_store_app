/// Firebase Storage path prefixes.
abstract final class StoragePaths {
  static String productImage(String productId, String fileName) =>
      'products/$productId/$fileName';
}
