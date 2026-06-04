import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_remote_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  WishlistRepositoryImpl(this._remote);
  final WishlistRemoteDataSource _remote;

  @override
  Future<List<WishlistItem>> getItems(String userId) {
    return _remote.fetchItems(userId);
  }

  @override
  Future<void> addItem(String userId, String productId) {
    return _remote.addItem(userId, productId);
  }
}
