import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<Either<Failure, void>> call({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    return await _repository.updateProfile(
      displayName: displayName,
      phoneNumber: phoneNumber,
      photoURL: photoURL,
    );
  }
}
