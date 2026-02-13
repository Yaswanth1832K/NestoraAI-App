import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/auth/domain/entities/user_entity.dart';

abstract interface class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? role,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Get the currently signed-in user
  Future<Either<Failure, UserEntity?>> getCurrentUser();
}
