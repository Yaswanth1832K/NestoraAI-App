import 'package:equatable/equatable.dart';

class ListingEntity extends Equatable {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String propertyType;
  final String furnishing; // Furnished, Semi-furnished, Unfurnished
  final int bedrooms;
  final int bathrooms;
  final double sqft;
  final Map<String, dynamic> address; // {street, city, state, pincode, lat, lng}
  final List<String> amenities;
  final List<String> images;
  final List<String> imageUrls;
  final List<String> searchTokens;
  final double latitude;
  final double longitude;
  final List<double>? embedding; // Optional, set by AI service
  final String status;
  final double? fraudRiskScore;
  final List<String>? fraudSignals;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DateTime> availableDates;

  List<String> get allImages => imageUrls.isNotEmpty ? imageUrls : images;

  String get city => address['city'] ?? 'Unknown City';

  const ListingEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'INR',
    required this.propertyType,
    this.furnishing = 'Unfurnished',
    required this.bedrooms,
    required this.bathrooms,
    required this.sqft,
    required this.address,
    required this.amenities,
    required this.images,
    required this.imageUrls,
    required this.searchTokens,
    this.latitude = 11.0168,
    this.longitude = 76.9558,
    this.embedding,
    required this.status,
    this.fraudRiskScore,
    this.fraudSignals,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.availableDates = const [],
  });

  ListingEntity copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? propertyType,
    String? furnishing,
    int? bedrooms,
    int? bathrooms,
    double? sqft,
    Map<String, dynamic>? address,
    List<String>? amenities,
    List<String>? images,
    List<String>? imageUrls,
    List<String>? searchTokens,
    double? latitude,
    double? longitude,
    List<double>? embedding,
    String? status,
    double? fraudRiskScore,
    List<String>? fraudSignals,
    double? averageRating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DateTime>? availableDates,
  }) {
    return ListingEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      propertyType: propertyType ?? this.propertyType,
      furnishing: furnishing ?? this.furnishing,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      sqft: sqft ?? this.sqft,
      address: address ?? this.address,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      imageUrls: imageUrls ?? this.imageUrls,
      searchTokens: searchTokens ?? this.searchTokens,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      embedding: embedding ?? this.embedding,
      status: status ?? this.status,
      fraudRiskScore: fraudRiskScore ?? this.fraudRiskScore,
      fraudSignals: fraudSignals ?? this.fraudSignals,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      availableDates: availableDates ?? this.availableDates,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        title,
        description,
        price,
        currency,
        propertyType,
        furnishing,
        bedrooms,
        bathrooms,
        sqft,
        address,
        amenities,
        images,
        imageUrls,
        searchTokens,
        latitude,
        longitude,
        embedding,
        status,
        fraudRiskScore,
        fraudSignals,
        averageRating,
        reviewCount,
        createdAt,
        updatedAt,
        availableDates,
      ];
}
