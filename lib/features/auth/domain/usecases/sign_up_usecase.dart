import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/auth/domain/entities/user_entity.dart';
import 'package:house_rental/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    String? role,
  }) {
    return _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      role: role,
    );
  }
}
