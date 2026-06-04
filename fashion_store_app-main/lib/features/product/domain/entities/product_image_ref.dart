import 'package:equatable/equatable.dart';

/// One stored Cloudinary asset reference (full gallery entry in Firestore).
class ProductImageRef extends Equatable {
  const ProductImageRef({
    required this.imageUrl,
    this.publicId = '',
  });

  final String imageUrl;
  final String publicId;

  @override
  List<Object?> get props => [imageUrl, publicId];
}
