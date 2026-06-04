import '../../domain/entities/wishlist_item.dart';

class WishlistItemModel extends WishlistItem {
  const WishlistItemModel({required super.productId});

  factory WishlistItemModel.fromJson(Map<String, dynamic> json, String docId) {
    return WishlistItemModel(
      productId: json['productId'] as String? ?? docId,
    );
  }

  Map<String, dynamic> toJson() => {'productId': productId};
}
