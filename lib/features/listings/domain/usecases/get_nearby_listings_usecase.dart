import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

class GetNearbyListingsUseCase {
  final ListingRepository _repository;

  const GetNearbyListingsUseCase(this._repository);

  Future<Either<Failure, List<ListingEntity>>> call(ListingEntity baseListing) {
    return _repository.getNearbyListings(baseListing);
  }
}
