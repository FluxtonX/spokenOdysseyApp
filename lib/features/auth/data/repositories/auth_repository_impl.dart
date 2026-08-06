import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;
  final fb.FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
    fb.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  String _handleFirebaseAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-cert-hash':
        return 'Google Sign-In requires adding your SHA-1 certificate fingerprint in Firebase Console settings.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    // 1. Authenticate with Firebase Auth SDK (Console visibility)
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Sign-In Warning/Error: ${e.code} - ${e.message}");
      // If user exists in backend but not in Firebase Auth, allow backend fallback
    } catch (e) {
      debugPrint("Firebase Auth Sign-In general error: $e");
    }

    // 2. Authenticate with Express Backend (JWT Token & DB sync)
    final data = await remoteDataSource.signIn(
      email: email,
      password: password,
    );
    final token = data['token'] ?? data['accessToken'] ?? '';
    final userJson = data['user'] ?? data['data'] ?? {};

    final userModel = UserModel.fromJson(userJson);
    await storageService.saveToken(token);
    await storageService.saveUserData(jsonEncode(userModel.toJson()));

    return userModel;
  }

  @override
  Future<User> signUp({required String email, required String password}) async {
    // 1. Create User in Firebase Authentication Console
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("Firebase Auth User created: ${credential.user?.uid}");
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Sign-Up Error: ${e.code} - ${e.message}");
      if (e.code == 'email-already-in-use') {
        throw Exception(_handleFirebaseAuthError(e));
      }
      // If user already exists in Firebase Auth, attempt signing in
      if (e.code == 'email-already-in-use') {
        try {
          await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Firebase Auth Sign-Up General Warning: $e");
    }

    // 2. Register/Sync with Express Backend database
    final data = await remoteDataSource.signUp(
      email: email,
      password: password,
    );
    final token = data['token'] ?? data['accessToken'] ?? '';
    final userJson = data['user'] ?? data['data'] ?? {};

    final userModel = UserModel.fromJson(userJson);
    if (token.isNotEmpty) {
      await storageService.saveToken(token);
    }
    await storageService.saveUserData(jsonEncode(userModel.toJson()));

    return userModel;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Firebase Auth Forgot Password Warning: $e");
    }
    await remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<bool> verifyOtp({required String email, required String otp}) async {
    return await remoteDataSource.verifyOtp(email: email, otp: otp);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String token,
  }) async {
    await remoteDataSource.resetPassword(
      email: email,
      newPassword: newPassword,
      token: token,
    );
  }

  @override
  Future<User> googleSignIn() async {
    try {
      final googleProvider = fb.GoogleAuthProvider();
      final userCredential = await _firebaseAuth.signInWithProvider(googleProvider);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Google Sign-In failed or was cancelled.');
      }

      final idToken = await firebaseUser.getIdToken() ?? '';

      // Sync Firebase Token with Express backend POST /api/auth/google
      final data = await remoteDataSource.googleLogin(idToken: idToken);
      final token = data['token'] ?? data['accessToken'] ?? idToken;
      final userJson = data['user'] ?? data['data'] ?? {};

      final userModel = UserModel.fromJson(userJson.isNotEmpty
          ? userJson
          : {
              'id': firebaseUser.uid,
              'email': firebaseUser.email ?? '',
              'displayName': firebaseUser.displayName ?? '',
              'photoURL': firebaseUser.photoURL ?? '',
            });

      if (token.isNotEmpty) {
        await storageService.saveToken(token);
      }
      await storageService.saveUserData(jsonEncode(userModel.toJson()));
      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("Firebase Google Sign-In Error: ${e.code} - ${e.message}");
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<User> appleSignIn() async {
    try {
      final appleProvider = fb.AppleAuthProvider();
      final userCredential = await _firebaseAuth.signInWithProvider(appleProvider);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Apple Sign-In failed or was cancelled.');
      }

      final idToken = await firebaseUser.getIdToken() ?? '';

      // Sync Firebase Token with Express backend POST /api/auth/google
      final data = await remoteDataSource.googleLogin(idToken: idToken);
      final token = data['token'] ?? data['accessToken'] ?? idToken;
      final userJson = data['user'] ?? data['data'] ?? {};

      final userModel = UserModel.fromJson(userJson.isNotEmpty
          ? userJson
          : {
              'id': firebaseUser.uid,
              'email': firebaseUser.email ?? '',
              'displayName': firebaseUser.displayName ?? 'Apple User',
              'photoURL': firebaseUser.photoURL ?? '',
            });

      if (token.isNotEmpty) {
        await storageService.saveToken(token);
      }
      await storageService.saveUserData(jsonEncode(userModel.toJson()));
      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("Firebase Apple Sign-In Error: ${e.code} - ${e.message}");
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      debugPrint("Apple Sign-In Error: $e");
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    await storageService.clearAll();
  }

  @override
  Future<User?> getSavedUser() async {
    final rawUser = await storageService.getUserData();
    if (rawUser != null) {
      try {
        final decoded = jsonDecode(rawUser);
        return UserModel.fromJson(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
