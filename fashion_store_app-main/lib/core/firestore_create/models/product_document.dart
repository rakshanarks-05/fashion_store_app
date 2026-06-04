import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../features/product/domain/entities/product_image_ref.dart';

/// Firestore document shape for the `products` collection.
///
/// Field names match Firestore keys exactly. [id] may be empty to request an
/// auto-generated document id when creating.
///
/// Gallery: [images] is the source of truth; `imageUrl` / `publicId` duplicate
/// the first item for older clients.
class ProductDocument extends Equatable {
  const ProductDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.collectionId,
    this.images = const [],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final List<ProductImageRef> images;
  final String categoryId;
  final String collectionId;

  /// Converts this model to a Firestore payload (excludes [id]; id is the doc path).
  Map<String, dynamic> toFirestoreMap() {
    final primary = images.isNotEmpty ? images.first : null;
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': primary?.imageUrl ?? '',
      if (primary != null && primary.publicId.isNotEmpty) 'publicId': primary.publicId,
      if (images.isNotEmpty)
        'images': images
            .map((e) => {
                  'imageUrl': e.imageUrl,
                  if (e.publicId.isNotEmpty) 'publicId': e.publicId,
                })
            .toList(),
      'categoryId': categoryId,
      'collectionId': collectionId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Builds from Firestore data plus document id.
  factory ProductDocument.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    final images = <ProductImageRef>[];
    final raw = data['images'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final u = (m['imageUrl'] as String?)?.trim() ?? '';
          if (u.isEmpty) continue;
          images.add(ProductImageRef(
            imageUrl: u,
            publicId: (m['publicId'] as String?)?.trim() ?? '',
          ));
        }
      }
    }
    if (images.isEmpty) {
      final legacy = (data['imageUrl'] as String?)?.trim() ?? '';
      if (legacy.isNotEmpty) {
        images.add(ProductImageRef(
          imageUrl: legacy,
          publicId: (data['publicId'] as String?)?.trim() ?? '',
        ));
      }
    }
    return ProductDocument(
      id: documentId,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      images: images,
      categoryId: data['categoryId'] as String? ??
          data['category'] as String? ??
          '',
      collectionId: data['collectionId'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, price, images, categoryId, collectionId];
}
