import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
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
      debugPrint(
        "Firebase Auth Sign-In Warning/Error: ${e.code} - ${e.message}",
      );
      // If user exists in backend but not in Firebase Auth, allow backend fallback
    } catch (e) {
      debugPrint("Firebase Auth Sign-In general error: $e");
    }

    // 2. Authenticate with Express Backend (JWT Token & DB sync)
    final data = await remoteDataSource.signIn(
      email: email,
      password: password,
    );

    if (data['mfaRequired'] == true) {
      final mfaToken = data['mfaToken'] as String;
      final availableMethods =
          (data['availableMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['totp'];
      throw MfaRequiredException(
        mfaToken: mfaToken,
        availableMethods: availableMethods,
        message: 'Two-factor authentication is required.',
      );
    }

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
      debugPrint("Firebase Auth Sign-Up Warning: ${e.code} - ${e.message}");
      if (e.code == 'email-already-in-use') {
        try {
          await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {}
      } else if (e.code == 'weak-password' || e.code == 'invalid-email') {
        throw Exception(_handleFirebaseAuthError(e));
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
      // 1. Trigger the native Google Sign-In bottom sheet
      final googleSignIn = GoogleSignIn(
        clientId: !kIsWeb && Platform.isIOS
            ? '884058304379-t5jeu8j0sjk4ptv43q5fbk7lid58pii0.apps.googleusercontent.com'
            : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In failed or was cancelled.');
      }

      // 2. Get auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Once signed in, return the UserCredential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase authentication with Google failed.');
      }

      // Sync Firebase Token with Express backend POST /api/auth/google
      final firebaseIdToken = await firebaseUser.getIdToken() ?? '';
      final data = await remoteDataSource.googleLogin(idToken: firebaseIdToken);
      final token = data['token'] ?? data['accessToken'] ?? firebaseIdToken;
      final userJson = data['user'] ?? data['data'] ?? {};

      final userModel = UserModel.fromJson(
        userJson.isNotEmpty
            ? userJson
            : {
                'id': firebaseUser.uid,
                'email': firebaseUser.email ?? '',
                'displayName': firebaseUser.displayName ?? '',
                'photoURL': firebaseUser.photoURL ?? '',
              },
      );

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
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final userCredential = await _firebaseAuth.signInWithProvider(
        appleProvider,
      );
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Apple Sign-In was cancelled.');
      }

      final idToken = await firebaseUser.getIdToken() ?? '';

      // Extract user's name (Apple provides name only on the FIRST authentication)
      String displayName = firebaseUser.displayName ?? '';
      if (displayName.isEmpty) {
        final profile = userCredential.additionalUserInfo?.profile;
        if (profile != null && profile['name'] != null) {
          final n = profile['name'];
          if (n is Map) {
            final first = n['firstName']?.toString() ?? '';
            final last = n['lastName']?.toString() ?? '';
            displayName = '$first $last'.trim();
          } else if (n is String) {
            displayName = n;
          }
        }
      }

      // Sync Firebase Token with backend POST /api/auth/google
      Map<String, dynamic> data = {};
      try {
        data = await remoteDataSource.googleLogin(idToken: idToken);
      } catch (err) {
        debugPrint("Backend token sync warning: $err");
      }

      final token = data['token'] ?? data['accessToken'] ?? idToken;
      final userJson = data['user'] ?? data['data'] ?? {};

      if (displayName.isEmpty && userJson['displayName'] != null) {
        displayName = userJson['displayName'];
      }
      if (displayName.isEmpty &&
          firebaseUser.email != null &&
          firebaseUser.email!.isNotEmpty) {
        displayName = firebaseUser.email!.split('@').first;
      }
      if (displayName.isEmpty) {
        displayName = 'Apple User';
      }

      final userModel = UserModel.fromJson(
        userJson.isNotEmpty
            ? userJson
            : {
                'id': firebaseUser.uid,
                'email': firebaseUser.email ?? '',
                'displayName': displayName,
                'photoURL': firebaseUser.photoURL ?? '',
              },
      );

      if (token.isNotEmpty) {
        await storageService.saveToken(token);
      }
      await storageService.saveUserData(jsonEncode(userModel.toJson()));
      return userModel;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("Firebase Apple Sign-In Error: ${e.code} - ${e.message}");
      if (e.code == 'canceled' ||
          e.code == 'popup-closed-by-user' ||
          e.code == 'web-context-cancelled' ||
          e.code == 'user-cancelled') {
        throw Exception('Apple Sign-In was cancelled.');
      }
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      debugPrint("Apple Sign-In Error: $e");
      final errStr = e.toString();
      if (errStr.contains('cancelled') || errStr.contains('canceled')) {
        throw Exception('Apple Sign-In was cancelled.');
      }
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await GoogleSignIn().signOut();
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

  @override
  Future<User> verifyTotpMfa({
    required String mfaToken,
    required String code,
  }) async {
    final data = await remoteDataSource.verifyTotpMfa(
      mfaToken: mfaToken,
      code: code,
    );

    final token = data['token'] ?? data['accessToken'] ?? '';
    final userJson = data['user'] ?? data['data'] ?? {};

    final userModel = UserModel.fromJson(userJson);
    await storageService.saveToken(token);
    await storageService.saveUserData(jsonEncode(userModel.toJson()));

    return userModel;
  }

  @override
  Future<User> verifyRecoveryMfa({
    required String mfaToken,
    required String code,
  }) async {
    final data = await remoteDataSource.verifyRecoveryMfa(
      mfaToken: mfaToken,
      code: code,
    );

    final token = data['token'] ?? data['accessToken'] ?? '';
    final userJson = data['user'] ?? data['data'] ?? {};

    final userModel = UserModel.fromJson(userJson);
    await storageService.saveToken(token);
    await storageService.saveUserData(jsonEncode(userModel.toJson()));

    return userModel;
  }
}
