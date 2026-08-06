import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase implements UseCase<void, String> {
  final AuthRepository repository;
  ForgotPasswordUseCase(this.repository);

  @override
  Future<void> call(String email) async {
    return await repository.forgotPassword(email: email);
  }
}
