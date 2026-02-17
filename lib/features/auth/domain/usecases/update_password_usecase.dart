import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/auth/domain/repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  final AuthRepository _repository;

  UpdatePasswordUseCase(this._repository);

  Future<Either<Failure, void>> call(String newPassword) {
    return _repository.updatePassword(newPassword);
  }
}
