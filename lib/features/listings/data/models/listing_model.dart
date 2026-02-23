import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';

class ListingModel extends ListingEntity {
  const ListingModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.description,
    required super.price,
    super.currency,
    required super.propertyType,
    required super.furnishing,
    required super.bedrooms,
    required super.bathrooms,
    required super.sqft,
    required super.address,
    required super.amenities,
    required super.images,
    required super.imageUrls,
    required super.searchTokens,
    super.latitude,
    super.longitude,
    super.embedding,
    required super.status,
    super.fraudRiskScore,
    super.fraudSignals,
    super.averageRating,
    super.reviewCount,
    required super.createdAt,
    required super.updatedAt,
    super.availableDates,
    super.aiSummaryBullets,
    super.safety,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Property',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      propertyType: json['propertyType'] as String? ?? 'Apartment',
      furnishing: json['furnishing'] as String? ?? 'Unfurnished',
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
      sqft: (json['sqft'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      address: json['address'] != null 
          ? Map<String, dynamic>.from(json['address'] as Map) 
          : {},
      amenities: json['amenities'] != null 
          ? List<String>.from(json['amenities'] as List) 
          : [],
      images: json['images'] != null 
          ? List<String>.from(json['images'] as List) 
          : [],
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls'] as List) 
          : [],
      searchTokens: json['searchTokens'] != null 
          ? List<String>.from(json['searchTokens'] as List) 
          : [],
      latitude: _safeParseDouble(json['latitude'], 11.0168),
      longitude: _safeParseDouble(json['longitude'], 76.9558),
      embedding: json['embedding'] != null
          ? List<double>.from(json['embedding'] as List)
          : null,
      status: json['status'] as String? ?? 'active',
      fraudRiskScore: (json['fraudRiskScore'] as num?)?.toDouble(),
      fraudSignals: json['fraudSignals'] != null
          ? List<String>.from(json['fraudSignals'] as List)
          : null,
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      availableDates: json['availableDates'] != null
          ? (json['availableDates'] as List)
              .map((d) => (d as Timestamp).toDate())
              .toList()
          : [],
      aiSummaryBullets: json['aiSummaryBullets'] != null
          ? List<String>.from(json['aiSummaryBullets'] as List)
          : null,
      safety: json['safety'] as String?,
    );
  }

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ListingModel.fromJson(data);
  }

  factory ListingModel.fromEntity(ListingEntity entity) {
    return ListingModel(
      id: entity.id,
      ownerId: entity.ownerId,
      title: entity.title,
      description: entity.description,
      price: entity.price,
      currency: entity.currency,
      propertyType: entity.propertyType,
      furnishing: entity.furnishing,
      bedrooms: entity.bedrooms,
      bathrooms: entity.bathrooms,
      sqft: entity.sqft,
      address: entity.address,
      amenities: entity.amenities,
      images: entity.images,
      imageUrls: entity.imageUrls,
      searchTokens: entity.searchTokens,
      latitude: entity.latitude,
      longitude: entity.longitude,
      embedding: entity.embedding,
      status: entity.status,
      fraudRiskScore: entity.fraudRiskScore,
      fraudSignals: entity.fraudSignals,
      averageRating: entity.averageRating,
      reviewCount: entity.reviewCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      availableDates: entity.availableDates,
      aiSummaryBullets: entity.aiSummaryBullets,
      safety: entity.safety,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'propertyType': propertyType,
      'furnishing': furnishing,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'sqft': sqft,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'address': address,
      'amenities': amenities,
      'images': images,
      'imageUrls': imageUrls,
      'searchTokens': searchTokens,
      'latitude': latitude,
      'longitude': longitude,
      'embedding': embedding,
      'status': status,
      'fraudRiskScore': fraudRiskScore,
      'fraudSignals': fraudSignals,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'availableDates': availableDates
          .map((d) => Timestamp.fromDate(d))
          .toList(),
      if (aiSummaryBullets != null) 'aiSummaryBullets': aiSummaryBullets,
      if (safety != null) 'safety': safety,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory ListingModel.fromMap(Map<String, dynamic> map) =>
      ListingModel.fromJson(map);

  static double _safeParseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
