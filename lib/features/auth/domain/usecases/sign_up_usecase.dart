import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpParams {
  final String email;
  final String password;
  SignUpParams({required this.email, required this.password});
}

class SignUpUseCase implements UseCase<User, SignUpParams> {
  final AuthRepository repository;
  SignUpUseCase(this.repository);

  @override
  Future<User> call(SignUpParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
    );
  }
}
