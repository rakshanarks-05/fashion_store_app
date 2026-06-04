import 'package:equatable/equatable.dart';

/// Home tab on the All Categories screen (All / Female / Male).
enum GenderTab {
  all,
  female,
  male,
}

extension GenderTabX on GenderTab {
  String get label => switch (this) {
        GenderTab.all => 'All',
        GenderTab.female => 'Female',
        GenderTab.male => 'Male',
      };
}

/// Coarse audience tag for mock filtering.
enum CategoryAudience {
  unisex,
  female,
  male,
}

/// One top-level category with optional sub-categories (expandable).
class CatalogCategoryGroup extends Equatable {
  const CatalogCategoryGroup({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.subcategories,
    this.audience = CategoryAudience.unisex,
  });

  final String id;
  final String name;
  final String imageUrl;
  final List<String> subcategories;
  final CategoryAudience audience;

  bool visibleFor(GenderTab tab) {
    switch (tab) {
      case GenderTab.all:
        return true;
      case GenderTab.female:
        return audience != CategoryAudience.male;
      case GenderTab.male:
        return audience != CategoryAudience.female;
    }
  }

  @override
  List<Object?> get props => [id, name, imageUrl, subcategories, audience];
}

/// Maps Firestore `gender` (`male` / `female` / `both`) to tab filtering.
/// Null or unknown values behave like `"both"` (unisex).
CategoryAudience categoryAudienceFromGender(String? gender) {
  switch ((gender ?? 'both').trim().toLowerCase()) {
    case 'male':
      return CategoryAudience.male;
    case 'female':
      return CategoryAudience.female;
    default:
      return CategoryAudience.unisex;
  }
}
