import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:house_rental/features/auth/data/models/user_model.dart';
import 'package:house_rental/core/errors/exceptions.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, {String? role});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> updatePassword(String newPassword);
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  });
  Future<void> updateUserRole(String uid, String newRole);
  Future<void> updateFcmToken(String token);
  /// Sign in with Google OAuth
  Future<UserModel> signInWithGoogle();
  /// Sign in with Facebook OAuth
  Future<UserModel> signInWithFacebook();
  /// Sign in with Apple OAuth
  Future<UserModel> signInWithApple();
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);
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

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const ServerException(message: 'User is not signed in');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Password update failed');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw const ServerException(message: 'User not logged in');

      // Update Firebase Auth profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore user document
      final Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (photoURL != null) updates['photoUrl'] = photoURL;
      
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      }
      
      await user.reload(); // Refresh user data
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────
  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // On Web, use the Firebase popup flow which is more reliable 
        // and doesn't require the People API to be manually enabled.
        final provider = GoogleAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn(
          clientId: '629169100807-k0e0lks9pu8v46oj2ahk0714maqh8pra.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw const ServerException(message: 'Google Sign-In cancelled');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      if (userCredential.user == null) {
        throw const ServerException(message: 'Google Sign-In failed');
      }
      return await _ensureUserDocument(userCredential.user!);
    } on ServerException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Google Sign-In failed');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Facebook Sign-In ──────────────────────────────────────────
  @override
  Future<UserModel> signInWithFacebook() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final provider = FacebookAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(provider);
      } else {
        final LoginResult facebookResult = await FacebookAuth.instance.login();
        if (facebookResult.status == LoginStatus.success) {
          final OAuthCredential credential = FacebookAuthProvider.credential(
            facebookResult.accessToken!.tokenString,
          );
          userCredential = await _firebaseAuth.signInWithCredential(credential);
        } else if (facebookResult.status == LoginStatus.cancelled) {
          throw const ServerException(message: 'Facebook Sign-In cancelled');
        } else {
          throw ServerException(message: facebookResult.message ?? 'Facebook Sign-In failed');
        }
      }

      if (userCredential.user == null) {
        throw const ServerException(message: 'Facebook Sign-In failed');
      }
      return await _ensureUserDocument(userCredential.user!);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // ── Apple Sign-In ─────────────────────────────────────────────
  @override
  Future<UserModel> signInWithApple() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final provider = AppleAuthProvider();
        userCredential = await _firebaseAuth.signInWithPopup(provider);
      } else {
        final AuthorizationCredentialAppleID appleIdCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
        final AuthCredential credential = oAuthProvider.credential(
          idToken: appleIdCredential.identityToken,
          accessToken: appleIdCredential.authorizationCode,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      if (userCredential.user == null) {
        throw const ServerException(message: 'Apple Sign-In failed');
      }
      return await _ensureUserDocument(userCredential.user!);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(message: e.message ?? 'Password reset failed');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
