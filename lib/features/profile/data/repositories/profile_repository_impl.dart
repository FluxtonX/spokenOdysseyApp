import 'package:spokenodyssey/features/auth/domain/entities/user.dart';
import '../../../../core/network/cache_manager.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> getMyProfile() async {
    const key = 'profile_me';
    final cached = CacheManager().get<User>(
      key,
      ttl: const Duration(minutes: 5),
    );
    if (cached != null) return cached;

    final user = await remoteDataSource.getMyProfile();
    CacheManager().set(key, user);
    return user;
  }

  @override
  Future<User> getUserProfile(String userId) async {
    final key = 'profile_$userId';
    final cached = CacheManager().get<User>(
      key,
      ttl: const Duration(minutes: 5),
    );
    if (cached != null) return cached;

    final user = await remoteDataSource.getUserProfile(userId);
    CacheManager().set(key, user);
    return user;
  }

  @override
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
  }) async {
    final user = await remoteDataSource.updateProfile(
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
    CacheManager().invalidate('profile_');
    return user;
  }
}
