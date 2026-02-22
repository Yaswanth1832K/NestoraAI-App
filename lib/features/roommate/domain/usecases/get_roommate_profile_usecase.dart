import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';
import 'package:house_rental/features/roommate/domain/repositories/roommate_repository.dart';

class GetRoommateProfileUseCase {
  final RoommateRepository repository;

  GetRoommateProfileUseCase(this.repository);

  Future<Either<Failure, RoommateEntity?>> call(String userId) {
    return repository.getRoommateProfile(userId);
  }
}
