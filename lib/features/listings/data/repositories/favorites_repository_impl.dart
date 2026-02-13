import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/core/errors/exceptions.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/favorites_repository.dart';
import 'package:house_rental/features/listings/data/datasources/favorites_remote_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _remoteDataSource;

  FavoritesRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, bool>> toggleFavorite(String userId, ListingEntity listing) async {
    try {
      final result = await _remoteDataSource.toggleFavorite(userId, listing);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Set<String>> watchFavoriteIds(String userId) {
    return _remoteDataSource.watchFavoriteIds(userId);
  }

  @override
  Stream<List<ListingEntity>> watchFavoriteListings(String userId) {
    return _remoteDataSource.watchFavoriteListings(userId);
  }
}
