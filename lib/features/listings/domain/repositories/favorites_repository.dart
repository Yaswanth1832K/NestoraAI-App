import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';

abstract interface class FavoritesRepository {
  /// Toggle a listing as favorite for a specific user
  Future<Either<Failure, bool>> toggleFavorite(String userId, ListingEntity listing);

  /// Watch all favorite listing IDs for a specific user
  Stream<Set<String>> watchFavoriteIds(String userId);

  /// Watch all favorite listings (summaries) for a specific user
  Stream<List<ListingEntity>> watchFavoriteListings(String userId);
}
