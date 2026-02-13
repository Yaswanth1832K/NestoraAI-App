import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

class GetListingByIdUseCase {
  final ListingRepository _repository;

  const GetListingByIdUseCase(this._repository);

  Future<Either<Failure, ListingEntity>> call(String id) {
    return _repository.getListingById(id);
  }
}
