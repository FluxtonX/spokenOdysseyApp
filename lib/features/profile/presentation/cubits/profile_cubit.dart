import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokenodyssey/features/auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';

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

  Future<void> loadProfile({String? userId}) async {
    try {
      emit(ProfileLoading());
      final user = userId != null
          ? await repository.getUserProfile(userId)
          : await repository.getMyProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? relationship,
    String? avatarPath,
  }) async {
    try {
      final updatedUser = await repository.updateProfile(
        displayName: displayName,
        bio: bio,
        location: location,
        relationship: relationship,
        avatarPath: avatarPath,
      );
      emit(ProfileLoaded(updatedUser));
      return true;
    } catch (e) {
      emit(ProfileError(e.toString()));
      return false;
    }
  }
}
