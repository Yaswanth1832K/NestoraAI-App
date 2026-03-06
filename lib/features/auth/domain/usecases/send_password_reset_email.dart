import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetEmail {
  final AuthRepository _repository;

  SendPasswordResetEmail(this._repository);

  Future<Either<Failure, void>> call(String email) async {
    return await _repository.sendPasswordResetEmail(email);
  }
}
