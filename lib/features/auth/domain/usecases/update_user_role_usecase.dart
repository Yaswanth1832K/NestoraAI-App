import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/auth/domain/repositories/auth_repository.dart';

class UpdateUserRoleUseCase {
  final AuthRepository _repository;

  UpdateUserRoleUseCase(this._repository);

  Future<Either<Failure, void>> call(String uid, String newRole) {
    return _repository.updateUserRole(uid, newRole);
  }
}
