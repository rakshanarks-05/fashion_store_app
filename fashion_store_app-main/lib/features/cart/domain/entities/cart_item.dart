import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.quantity,
    this.selectedSize,
  });

  final String productId;
  final int quantity;
  final String? selectedSize;

  @override
  List<Object?> get props => [productId, quantity, selectedSize];
}
