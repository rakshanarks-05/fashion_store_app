import 'package:equatable/equatable.dart';

/// Firestore document shape for the `collections` collection (curated product groups).
class CollectionDocument extends Equatable {
  const CollectionDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;

  Map<String, dynamic> toFirestoreMap() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
      };

  factory CollectionDocument.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return CollectionDocument(
      id: documentId,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, description, imageUrl];
}
