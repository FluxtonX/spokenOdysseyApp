import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;
  SignInParams({required this.email, required this.password});
}

class SignInUseCase implements UseCase<User, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<User> call(SignInParams params) async {
    return await repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}
