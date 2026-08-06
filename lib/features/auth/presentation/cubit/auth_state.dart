import '../../domain/entities/user.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class ForgotPasswordSent extends AuthState {
  final String email;
  const ForgotPasswordSent(this.email);
}

class OtpVerified extends AuthState {
  final String email;
  final String otp;
  const OtpVerified({required this.email, required this.otp});
}

class PasswordResetSuccess extends AuthState {
  final String message;
  const PasswordResetSuccess([this.message = 'Password changed!']);
}
