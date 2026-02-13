import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/auth/data/models/user_model.dart';
import 'package:house_rental/core/errors/exceptions.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, {String? role});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._firebaseAuth, this._firestore);

  /// Ensures user document exists in Firestore with role field
  Future<UserModel> _ensureUserDocument(User firebaseUser, {String? role}) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // Create new user document with specified or default renter role
      final newUser = UserModel.fromFirebaseUser(firebaseUser, role: role ?? 'renter');
      await userDoc.set(newUser.toFirestore());
      return newUser;
    } else {
      // User exists, fetch from Firestore to get role
      return UserModel.fromFirestore(snapshot);
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw const ServerException(message: 'User is null after sign in');
      }
      return await _ensureUserDocument(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Authentication failed');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, {String? role}) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw const ServerException(message: 'User is null after sign up');
      }
      return await _ensureUserDocument(userCredential.user!, role: role);
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Sign up failed');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return await _ensureUserDocument(user);
      }
      return null;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
