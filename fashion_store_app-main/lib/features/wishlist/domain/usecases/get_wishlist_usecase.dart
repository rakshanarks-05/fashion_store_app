import '../entities/wishlist_item.dart';
import '../repositories/wishlist_repository.dart';

class GetWishlistUseCase {
  GetWishlistUseCase(this._repository);
  final WishlistRepository _repository;

  Future<List<WishlistItem>> call(String userId) {
    return _repository.getItems(userId);
  }
}
