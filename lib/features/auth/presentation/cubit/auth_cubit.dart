import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final AuthRepository authRepository;

  AuthCubit({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.forgotPasswordUseCase,
    required this.verifyOtpUseCase,
    required this.resetPasswordUseCase,
    required this.authRepository,
  }) : super(AuthInitial());

  String _extractErrorMessage(dynamic e) {
    if (e is ServerException) return e.message;
    if (e is Failure) return e.message;
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return msg;
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getSavedUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await signInUseCase(
        SignInParams(email: email, password: password),
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await signUpUseCase(
        SignUpParams(email: email, password: password),
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> forgotPassword(String email) async {
    emit(AuthLoading());
    try {
      await forgotPasswordUseCase(email);
      emit(ForgotPasswordSent(email));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    emit(AuthLoading());
    try {
      final isValid = await verifyOtpUseCase(
        VerifyOtpParams(email: email, otp: otp),
      );
      if (isValid) {
        emit(OtpVerified(email: email, otp: otp));
      } else {
        emit(const AuthError('Invalid verification code. Please try again.'));
      }
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String token,
  }) async {
    emit(AuthLoading());
    try {
      await resetPasswordUseCase(
        ResetPasswordParams(
          email: email,
          newPassword: newPassword,
          token: token,
        ),
      );
      emit(const PasswordResetSuccess('Password changed!'));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> googleSignIn() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.googleSignIn();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> appleSignIn() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.appleSignIn();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(_extractErrorMessage(e)));
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    emit(Unauthenticated());
  }
}
