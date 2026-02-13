import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/domain/repositories/listing_repository.dart';

class GetMyListingsUseCase {
  final ListingRepository repository;

  GetMyListingsUseCase(this.repository);

  Future<Either<Failure, List<ListingEntity>>> call(String userId) {
    return repository.getMyListings(userId);
  }
}
