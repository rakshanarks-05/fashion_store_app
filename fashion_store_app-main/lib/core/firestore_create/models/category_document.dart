import 'package:equatable/equatable.dart';

/// Firestore document shape for the `categories` collection.
class CategoryDocument extends Equatable {
  const CategoryDocument({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.gender,
  });

  final String id;
  final String name;
  final String imageUrl;

  /// Values: `"male"`, `"female"`, `"both"`, `"kids"`.
  ///
  /// Serialized as `"both"` when null.
  final String? gender;

  Map<String, dynamic> toFirestoreMap() => {
        'name': name,
        'imageUrl': imageUrl,
        'gender': gender ?? 'both',
      };

  factory CategoryDocument.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return CategoryDocument(
      id: documentId,
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      gender: _genderFromJson(data['gender']),
    );
  }

  factory CategoryDocument.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    return CategoryDocument(
      id: id,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      gender: _genderFromJson(json['gender']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'gender': gender ?? 'both',
      };

  /// Missing, null, empty, or invalid values become `null` (treated as `"both"` for filtering).
  static String? _genderFromJson(Object? value) {
    if (value == null) return null;
    if (value is! String) return null;
    final v = value.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == 'male' || v == 'female' || v == 'both') return v;
    if (v == 'kids') return 'kids';
    return null;
  }

  @override
  List<Object?> get props => [id, name, imageUrl, gender];
}
