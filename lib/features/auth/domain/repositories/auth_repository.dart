import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> signIn({required String email, required String password});
  Future<User> signUp({required String email, required String password});
  Future<void> forgotPassword({required String email});
  Future<bool> verifyOtp({required String email, required String otp});
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String token,
  });
  Future<User> googleSignIn();
  Future<User> appleSignIn();
  Future<void> signOut();
  Future<User?> getSavedUser();
  Future<User> verifyTotpMfa({required String mfaToken, required String code});
  Future<User> verifyRecoveryMfa({
    required String mfaToken,
    required String code,
  });
}

class MfaRequiredException implements Exception {
  final String mfaToken;
  final List<String> availableMethods;
  final String message;
  MfaRequiredException({
    required this.mfaToken,
    required this.availableMethods,
    required this.message,
  });

  @override
  String toString() => message;
}
