import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/roommate/domain/entities/roommate_entity.dart';

abstract class RoommateRepository {
  Future<Either<Failure, void>> saveRoommateProfile(RoommateEntity roommate);
  Future<Either<Failure, RoommateEntity?>> getRoommateProfile(String userId);
  Future<Either<Failure, List<RoommateEntity>>> findMatches(String city, int budget, String gender);
}
