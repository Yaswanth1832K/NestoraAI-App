import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/exceptions.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';
import 'package:house_rental/features/listings/data/datasources/listing_remote_datasource.dart';
import 'package:house_rental/features/listings/data/models/listing_model.dart';

class ListingRepositoryImpl implements ListingRepository {
  final ListingRemoteDataSource _remoteDataSource;

  ListingRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<ListingEntity>>> getListings({
    ListingFilter? filter,
    int limit = 10,
    String? lastListingId,
  }) async {
    try {
      final listings = await _remoteDataSource.getListings(
        filter: filter,
        limit: limit,
        lastListingId: lastListingId,
      );
      return Right(listings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ListingEntity>> getListingById(String id) async {
    try {
      final listing = await _remoteDataSource.getListingById(id);
      return Right(listing);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createListing(ListingEntity listing) async {
    try {
      final listingModel = ListingModel.fromEntity(listing);
      await _remoteDataSource.createListing(listingModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateListing(ListingEntity listing) async {
    try {
      final listingModel = ListingModel.fromEntity(listing);
      await _remoteDataSource.updateListing(listingModel);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteListing(String id) async {
    try {
      await _remoteDataSource.deleteListing(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ListingEntity>>> getNearbyListings(ListingEntity baseListing) async {
    try {
      final listings = await _remoteDataSource.getNearbyListings(baseListing);
      return Right(listings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ListingEntity>>> getListingsInBounds(
      double minLat, double maxLat, double minLng, double maxLng) async {
    try {
      final listings = await _remoteDataSource.getListingsInBounds(
          minLat, maxLat, minLng, maxLng);
      return Right(listings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ListingEntity>>> getMyListings(String userId) async {
    try {
      final listings = await _remoteDataSource.getMyListings(userId);
      return Right(listings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
