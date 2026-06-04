import 'package:equatable/equatable.dart';

import 'product_image_ref.dart';

/// Domain product aligned with Firestore `products` documents.
///
/// [categoryId] is populated from the `category` or `categoryId` field in
/// Firestore so filters and UI stay consistent.
///
/// Gallery is stored as `images: [{ imageUrl, publicId }, ...]`; legacy docs
/// with only `imageUrl` / `publicId` are mapped to a single [images] entry.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.images = const [],
    this.collectionId = '',
    this.isFeatured = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final List<ProductImageRef> images;

  /// Primary image for list/cart/checkout (first gallery photo).
  String get imageUrl => images.isNotEmpty ? images.first.imageUrl : '';

  /// Cloudinary `public_id` for the primary image (legacy / first slot).
  String get publicId => images.isNotEmpty ? images.first.publicId : '';

  final String categoryId;
  final String collectionId;
  final bool isFeatured;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        images,
        categoryId,
        collectionId,
        isFeatured,
        createdAt,
      ];
}
