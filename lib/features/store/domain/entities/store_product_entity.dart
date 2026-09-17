class StoreProductEntity {
  final String id;
  final String slug;
  final String name;
  final String? tagline;
  final String? badge;
  final double rating;
  final int reviewsCount;
  final double basePrice;
  final double? originalPrice;
  final String description;
  final List<String> features;
  final Map<String, dynamic>? specs;
  final List<String> images;

  const StoreProductEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.tagline,
    this.badge,
    required this.rating,
    required this.reviewsCount,
    required this.basePrice,
    this.originalPrice,
    required this.description,
    required this.features,
    this.specs,
    required this.images,
  });
}
