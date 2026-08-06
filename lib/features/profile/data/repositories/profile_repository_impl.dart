import 'package:spokenodyssey/features/auth/domain/entities/user.dart';

import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> getMyProfile() async {
    return await remoteDataSource.getMyProfile();
  }

  @override
  Future<User> getUserProfile(String userId) async {
    return await remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<User> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? relationship,
    String? avatarPath,
  }) async {
    return await remoteDataSource.updateProfile(
      displayName: displayName,
      bio: bio,
      location: location,
      relationship: relationship,
      avatarPath: avatarPath,
    );
  }
}
