import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';

class ListingFilter extends Equatable {
  final String? searchQuery;
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final int? bathrooms;
  final String? furnishing;
  final List<String>? amenities;
  final String? propertyType;
  final String? allowedTenants; // Bachelors, Family, etc.
  final bool? isVerified;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? guests;
  final double? minRating;
  final double? minSqft;
  final double? maxSqft;
  final bool? availableNow;

  ListingFilter({
    this.searchQuery,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.furnishing,
    this.amenities,
    this.propertyType,
    this.allowedTenants,
    this.isVerified,
    this.startDate,
    this.endDate,
    this.guests,
    this.minRating,
    this.minSqft,
    this.maxSqft,
    this.availableNow,
  });

  ListingFilter copyWith({
    String? searchQuery,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    String? furnishing,
    List<String>? amenities,
    String? propertyType,
    DateTime? startDate,
    DateTime? endDate,
    int? guests,
    double? minRating,
    double? minSqft,
    double? maxSqft,
    bool? availableNow,
  }) {
    return ListingFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      city: city ?? this.city,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      furnishing: furnishing ?? this.furnishing,
      amenities: amenities ?? this.amenities,
      propertyType: propertyType ?? this.propertyType,
      allowedTenants: allowedTenants ?? this.allowedTenants,
      isVerified: isVerified ?? this.isVerified,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      guests: guests ?? this.guests,
      minRating: minRating ?? this.minRating,
      minSqft: minSqft ?? this.minSqft,
      maxSqft: maxSqft ?? this.maxSqft,
      availableNow: availableNow ?? this.availableNow,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        city,
        minPrice,
        maxPrice,
        bedrooms,
        bathrooms,
        furnishing,
        amenities,
        propertyType,
        allowedTenants,
        isVerified,
        startDate,
        endDate,
        guests,
        minRating,
        minSqft,
        maxSqft,
        availableNow,
      ];
}

abstract interface class ListingRepository {
  /// Get paginated listings with optional filters
  Future<Either<Failure, List<ListingEntity>>> getListings({
    ListingFilter? filter,
    int limit = 10,
    String? lastListingId, // For pagination
  });

  /// Get a single listing by ID
  Future<Either<Failure, ListingEntity>> getListingById(String id);

  /// Create a new listing
  Future<Either<Failure, void>> createListing(ListingEntity listing);

  /// Update an existing listing
  Future<Either<Failure, void>> updateListing(ListingEntity listing);

  /// Delete a listing
  Future<Either<Failure, void>> deleteListing(String id);

  /// Get nearby listings based on similarity (price and bedrooms)
  Future<Either<Failure, List<ListingEntity>>> getNearbyListings(ListingEntity baseListing);

  /// Get listings within geographical bounds
  Future<Either<Failure, List<ListingEntity>>> getListingsInBounds(
      double minLat, double maxLat, double minLng, double maxLng);

  /// Get listings created by a specific user
  Future<Either<Failure, List<ListingEntity>>> getMyListings(String userId);
}
