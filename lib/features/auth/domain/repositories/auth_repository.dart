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
}
