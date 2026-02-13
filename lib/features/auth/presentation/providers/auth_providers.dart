import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:house_rental/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:house_rental/features/auth/data/models/user_model.dart';
import 'package:house_rental/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:house_rental/features/auth/domain/repositories/auth_repository.dart';
import 'package:house_rental/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:house_rental/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:house_rental/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:house_rental/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:house_rental/features/auth/domain/entities/user_entity.dart';

// Data Layer Providers
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

// Domain Layer Providers (UseCases)
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.read(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.read(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.read(authRepositoryProvider));
});


final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

// Role-based Providers (Real-time)
final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  
  if (user == null) return Stream.value(null);

  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });
});

final userRoleProvider = Provider<AsyncValue<String>>((ref) {
  final userSnapshot = ref.watch(currentUserProvider);
  return userSnapshot.whenData((user) => user?.role ?? 'renter');
});

final isOwnerProvider = Provider<AsyncValue<bool>>((ref) {
  final roleSnapshot = ref.watch(userRoleProvider);
  return roleSnapshot.whenData((role) => role == 'owner');
});
