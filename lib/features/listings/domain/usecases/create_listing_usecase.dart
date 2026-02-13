import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

class CreateListingUseCase {
  final ListingRepository _repository;

  const CreateListingUseCase(this._repository);

  Future<Either<Failure, void>> call(ListingEntity listing) {
    return _repository.createListing(listing);
  }
}
