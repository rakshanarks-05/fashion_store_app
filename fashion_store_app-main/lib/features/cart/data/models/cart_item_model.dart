import '../../domain/entities/cart_item.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.productId,
    required super.quantity,
    super.selectedSize,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json, String docId) {
    final size = (json['selectedSize'] as String?)?.trim();
    return CartItemModel(
      productId: json['productId'] as String? ?? docId,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selectedSize: (size != null && size.isNotEmpty) ? size : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        if (selectedSize != null && selectedSize!.trim().isNotEmpty)
          'selectedSize': selectedSize!.trim(),
      };
}
