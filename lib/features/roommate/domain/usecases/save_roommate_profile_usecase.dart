import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';
import 'package:house_rental/features/roommate/domain/repositories/roommate_repository.dart';

class SaveRoommateProfileUseCase {
  final RoommateRepository repository;

  SaveRoommateProfileUseCase(this.repository);

  Future<Either<Failure, void>> call(RoommateEntity roommate) {
    return repository.saveRoommateProfile(roommate);
  }
}
