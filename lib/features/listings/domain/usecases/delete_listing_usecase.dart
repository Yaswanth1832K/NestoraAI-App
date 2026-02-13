import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

class DeleteListingUseCase {
  final ListingRepository _repository;

  const DeleteListingUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) {
    return _repository.deleteListing(id);
  }
}
