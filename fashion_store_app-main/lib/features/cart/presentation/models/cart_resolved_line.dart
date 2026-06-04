import 'package:equatable/equatable.dart';

import '../../../product/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';

/// Cart row with catalog [product] when available (otherwise unknown id).
class CartResolvedLine extends Equatable {
  const CartResolvedLine({
    required this.cartItem,
    this.product,
  });

  final CartItem cartItem;
  final Product? product;

  String get productId => cartItem.productId;

  @override
  List<Object?> get props => [cartItem, product];
}
