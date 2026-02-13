import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

class GetListingsInBoundsUseCase {
  final ListingRepository _repository;

  const GetListingsInBoundsUseCase(this._repository);

  Future<Either<Failure, List<ListingEntity>>> call(
      double minLat, double maxLat, double minLng, double maxLng) {
    return _repository.getListingsInBounds(minLat, maxLat, minLng, maxLng);
  }
}
