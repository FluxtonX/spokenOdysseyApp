import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  final String email;
  final String newPassword;
  final String token;
  ResetPasswordParams({
    required this.email,
    required this.newPassword,
    required this.token,
  });
}

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  @override
  Future<void> call(ResetPasswordParams params) async {
    return await repository.resetPassword(
      email: params.email,
      newPassword: params.newPassword,
      token: params.token,
    );
  }
}
