import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';
import 'package:house_rental/features/roommate/domain/repositories/roommate_repository.dart';

class FindRoommateMatchesUseCase {
  final RoommateRepository repository;

  FindRoommateMatchesUseCase(this.repository);

  Future<Either<Failure, List<RoommateEntity>>> call(String city, int budget, String gender) {
    return repository.findMatches(city, budget, gender);
  }
}
