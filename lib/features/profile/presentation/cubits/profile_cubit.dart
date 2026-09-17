import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokenodyssey/features/auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/error/exceptions.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  ProfileLoaded(this.user);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(ProfileInitial());

  Future<void> loadProfile({String? userId, bool forceRefresh = false}) async {
    try {
      if (state is! ProfileLoaded || forceRefresh) {
        if (state is! ProfileLoaded) emit(ProfileLoading());
      }
      final user = userId != null
          ? await repository.getUserProfile(userId)
          : await repository.getMyProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      if (state is! ProfileLoaded) {
        emit(ProfileError(ErrorParser.extractMessage(e)));
      }
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? profession,
    String? location,
    String? birthDate,
    String? lifeMotto,
    List<String>? expertise,
    String? relationship,
    String? avatarPath,
    String? coverPath,
  }) async {
    try {
      final updatedUser = await repository.updateProfile(
        displayName: displayName,
        bio: bio,
        profession: profession,
        location: location,
        birthDate: birthDate,
        lifeMotto: lifeMotto,
        expertise: expertise,
        relationship: relationship,
        avatarPath: avatarPath,
        coverPath: coverPath,
      );
      emit(ProfileLoaded(updatedUser));
      return true;
    } catch (e) {
      emit(ProfileError(ErrorParser.extractMessage(e)));
      return false;
    }
  }
}
