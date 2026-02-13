import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/ai_services/data/datasources/ai_remote_datasource.dart';

class SearchResult {
  final List<ListingEntity> listings;
  final ListingFilter filter;

  SearchResult({required this.listings, required this.filter});
}

class NaturalLanguageSearchUseCase {
  final AIRemoteDataSource _aiRemoteDataSource;
  final ListingRepository _listingRepository;

  const NaturalLanguageSearchUseCase(
    this._aiRemoteDataSource,
    this._listingRepository,
  );

  Future<Either<Failure, SearchResult>> call({
    required String query,
  }) async {
    try {
      // 1. Get response from AI Service
      final aiResponse = await _aiRemoteDataSource.naturalLanguageSearch(
        query: query,
      );

      // 2. Check success flag
      if (aiResponse['success'] == false) {
        return Left(ServerFailure(message: 'AI Search failed: ${aiResponse['error'] ?? 'Unknown error'}'));
      }

      // 3. Extract filters
      final filters = aiResponse['filters'] as Map<String, dynamic>? ?? {};
      
      // 4. Map to ListingFilter
      final listingFilter = ListingFilter(
        minPrice: filters['min_price'] is num 
            ? (filters['min_price'] as num).toDouble() 
            : null,
        maxPrice: filters['max_price'] is num 
            ? (filters['max_price'] as num).toDouble() 
            : null,
        bedrooms: filters['bedrooms'] is int ? filters['bedrooms'] as int : null,
        city: filters['city'] as String?,
        propertyType: filters['property_type'] as String?,
      );

      // 5. Fetch listings
      final result = await _listingRepository.getListings(
        filter: listingFilter,
      );

      return result.fold(
        (failure) => Left(failure),
        (listings) => Right(SearchResult(listings: listings, filter: listingFilter)),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'NLP Search Error: $e'));
    }
  }
}
