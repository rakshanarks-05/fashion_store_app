import '../entities/wishlist_item.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> getItems(String userId);
  Future<void> addItem(String userId, String productId);
}
