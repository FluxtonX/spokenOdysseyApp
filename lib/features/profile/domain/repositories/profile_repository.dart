import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<User> getMyProfile();
  Future<User> getUserProfile(String userId);
  Future<User> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? relationship,
    String? avatarPath,
  });
}
