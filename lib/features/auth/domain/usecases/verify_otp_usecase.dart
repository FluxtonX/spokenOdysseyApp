import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpParams {
  final String email;
  final String otp;
  VerifyOtpParams({required this.email, required this.otp});
}

class VerifyOtpUseCase implements UseCase<bool, VerifyOtpParams> {
  final AuthRepository repository;
  VerifyOtpUseCase(this.repository);

  @override
  Future<bool> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(email: params.email, otp: params.otp);
  }
}
