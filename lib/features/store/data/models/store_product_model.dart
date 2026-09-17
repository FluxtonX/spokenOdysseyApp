import '../../domain/entities/store_product_entity.dart';

class StoreProductModel extends StoreProductEntity {
  const StoreProductModel({
    required super.id,
    required super.slug,
    required super.name,
    super.tagline,
    super.badge,
    required super.rating,
    required super.reviewsCount,
    required super.basePrice,
    super.originalPrice,
    required super.description,
    required super.features,
    super.specs,
    required super.images,
  });

  factory StoreProductModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedFeatures = [];
    if (json['features'] is List) {
      parsedFeatures = (json['features'] as List)
          .map((e) => e.toString())
          .toList();
    }

    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['images'] is Map &&
        (json['images'] as Map)['main'] != null) {
      parsedImages = [(json['images'] as Map)['main'].toString()];
    }

    return StoreProductModel(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? 'Odyssey Memory Pod',
      tagline: json['tagline'] as String?,
      badge: json['badge'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 149.99,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      description:
          json['description'] as String? ??
          'High-fidelity audio recording hardware.',
      features: parsedFeatures,
      specs: json['specs'] is Map<String, dynamic> ? json['specs'] : null,
      images: parsedImages,
    );
  }
}
