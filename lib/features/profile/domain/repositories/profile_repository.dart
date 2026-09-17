import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<User> getMyProfile();
  Future<User> getUserProfile(String userId);
  Future<User> updateProfile({
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
  });
}
