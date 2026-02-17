import 'package:dartz/dartz.dart';
import 'package:house_rental/core/errors/exceptions.dart';
import 'package:house_rental/core/errors/failures.dart';
import 'package:house_rental/features/auth/domain/entities/user_entity.dart';
import 'package:house_rental/features/auth/domain/repositories/auth_repository.dart';
import 'package:house_rental/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:house_rental/features/notifications/domain/repositories/notification_repository.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final NotificationRepository _notificationRepository;
  final _uuid = const Uuid();

  AuthRepositoryImpl(this._remoteDataSource, this._notificationRepository);

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signInWithEmailAndPassword(email, password);
      
      // Trigger Login Notification (Non-blocking)
      try {
        await _notificationRepository.addNotification(
          user.uid,
          NotificationEntity(
            id: _uuid.v4(),
            title: "Login Activity",
            body: "You've successfully logged into your account.",
            timestamp: DateTime.now(),
            type: 'alert',
            isRead: false,
          ),
        );
      } catch (e) {
        debugPrint("Notification Error (Login): $e");
      }

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final user = await _remoteDataSource.signUpWithEmailAndPassword(email, password, role: role);

      // Trigger Signup Notification (Non-blocking)
      try {
        await _notificationRepository.addNotification(
          user.uid,
          NotificationEntity(
            id: _uuid.v4(),
            title: "Welcome to Nestora!",
            body: "Your account has been created successfully. Welcome aboard!",
            timestamp: DateTime.now(),
            type: 'success',
            isRead: false,
          ),
        );
      } catch (e) {
        debugPrint("Notification Error (Signup): $e");
      }

      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      await _remoteDataSource.updatePassword(newPassword);

      // Trigger Security Alert Notification (Non-blocking)
      try {
        final user = await _remoteDataSource.getCurrentUser();
        if (user != null) {
          await _notificationRepository.addNotification(
            user.uid,
            NotificationEntity(
              id: _uuid.v4(),
              title: "Security Alert",
              body: "Your password was recently changed. If you didn't do this, contact support.",
              timestamp: DateTime.now(),
              type: 'alert',
              isRead: false,
            ),
          );
        }
      } catch (e) {
        debugPrint("Notification Error (Security): $e");
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole(String uid, String newRole) async {
    try {
      await _remoteDataSource.updateUserRole(uid, newRole);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      await _remoteDataSource.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoURL: photoURL,
      );

      // Trigger Profile Updated Notification (Non-blocking)
      try {
        final user = await _remoteDataSource.getCurrentUser();
        if (user != null) {
          await _notificationRepository.addNotification(
            user.uid,
            NotificationEntity(
              id: _uuid.v4(),
              title: "Profile Updated",
              body: "Your personal information has been successfully updated.",
              timestamp: DateTime.now(),
              type: 'success',
              isRead: false,
            ),
          );
        }
      } catch (e) {
        debugPrint("Notification Error (Profile): $e");
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
