import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/product_image_ref.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.categoryId,
    super.images = const [],
    super.collectionId = '',
    super.isFeatured = false,
    super.createdAt,
  });

  /// Parses a plain JSON-style map (e.g. from cache). [documentId] wins over
  /// optional `id` in the map.
  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    final id = (json['id'] as String?)?.trim();
    final images = _parseImages(json);
    return ProductModel(
      id: (id != null && id.isNotEmpty) ? id : documentId,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      images: images,
      categoryId: json['categoryId'] as String? ??
          json['category'] as String? ??
          '',
      collectionId: json['collectionId'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  static List<ProductImageRef> _parseImages(Map<String, dynamic> json) {
    final out = <ProductImageRef>[];
    final raw = json['images'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final u = (m['imageUrl'] as String?)?.trim() ?? '';
          if (u.isEmpty) continue;
          out.add(ProductImageRef(
            imageUrl: u,
            publicId: (m['publicId'] as String?)?.trim() ?? '',
          ));
        }
      }
    }
    if (out.isEmpty) {
      final legacy = (json['imageUrl'] as String?)?.trim() ?? '';
      if (legacy.isNotEmpty) {
        out.add(ProductImageRef(
          imageUrl: legacy,
          publicId: (json['publicId'] as String?)?.trim() ?? '',
        ));
      }
    }
    return out;
  }

  factory ProductModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return ProductModel(
        id: doc.id,
        name: '',
        description: '',
        price: 0,
        categoryId: '',
        images: const [],
      );
    }
    return ProductModel.fromJson(data, doc.id);
  }

  static DateTime? _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        if (publicId.isNotEmpty) 'publicId': publicId,
        if (images.isNotEmpty)
          'images': images
              .map((e) => {
                    'imageUrl': e.imageUrl,
                    if (e.publicId.isNotEmpty) 'publicId': e.publicId,
                  })
              .toList(),
        'category': categoryId,
        'categoryId': categoryId,
        if (collectionId.isNotEmpty) 'collectionId': collectionId,
        'isFeatured': isFeatured,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };
}
