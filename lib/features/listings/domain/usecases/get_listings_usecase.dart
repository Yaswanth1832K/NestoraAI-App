import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

class GetListingsUseCase {
  final ListingRepository _repository;

  const GetListingsUseCase(this._repository);

  Future<Either<Failure, List<ListingEntity>>> call({
    ListingFilter? filter,
    int limit = 10,
    String? lastListingId,
  }) {
    return _repository.getListings(
      filter: filter,
      limit: limit,
      lastListingId: lastListingId,
    );
  }
}
