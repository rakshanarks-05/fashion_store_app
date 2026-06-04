import 'package:equatable/equatable.dart';

class WishlistItem extends Equatable {
  const WishlistItem({required this.productId});

  final String productId;

  @override
  List<Object?> get props => [productId];
}
