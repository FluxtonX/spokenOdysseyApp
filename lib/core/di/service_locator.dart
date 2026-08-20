import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

// Profile
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/cubits/profile_cubit.dart';
import '../../features/profile/presentation/cubits/followers_cubit.dart';

// Memories
import '../../features/memories/data/datasources/memories_remote_datasource.dart';
import '../../features/memories/data/repositories/memories_repository_impl.dart';
import '../../features/memories/domain/repositories/memories_repository.dart';
import '../../features/memories/presentation/cubits/memories_cubit.dart';
import '../../features/memories/presentation/cubits/memory_detail_cubit.dart';

// Record
import '../../features/record/presentation/cubit/record_cubit.dart';

// Albums
import '../../features/albums/data/datasources/albums_remote_datasource.dart';
import '../../features/albums/data/repositories/albums_repository_impl.dart';
import '../../features/albums/domain/repositories/albums_repository.dart';
import '../../features/albums/presentation/cubits/albums_cubit.dart';

// Family
import '../../features/family/data/datasources/family_remote_datasource.dart';
import '../../features/family/data/repositories/family_repository_impl.dart';
import '../../features/family/domain/repositories/family_repository.dart';
import '../../features/family/presentation/cubits/family_cubit.dart';

// Discover
import '../../features/discover/data/datasources/discover_remote_datasource.dart';
import '../../features/discover/data/repositories/discover_repository_impl.dart';
import '../../features/discover/domain/repositories/discover_repository.dart';
import '../../features/discover/presentation/cubits/discover_cubit.dart';

// Notifications
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/presentation/cubits/notifications_cubit.dart';

// Settings
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubits/settings_cubit.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // Storage & Network Services
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(storageService: sl()));

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<MemoriesRemoteDataSource>(
    () => MemoriesRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AlbumsRemoteDataSource>(
    () => AlbumsRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<FamilyRemoteDataSource>(
    () => FamilyRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<DiscoverRemoteDataSource>(
    () => DiscoverRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), storageService: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MemoriesRepository>(
    () => MemoriesRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AlbumsRepository>(
    () => AlbumsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DiscoverRepository>(
    () => DiscoverRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // Cubits
  sl.registerLazySingleton(
    () => AuthCubit(
      signInUseCase: sl(),
      signUpUseCase: sl(),
      forgotPasswordUseCase: sl(),
      verifyOtpUseCase: sl(),
      resetPasswordUseCase: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerFactory(() => ProfileCubit(repository: sl()));
  sl.registerFactory(() => FollowersCubit(discoverRepository: sl()));
  sl.registerFactory(() => MemoriesCubit(repository: sl()));
  sl.registerFactory(() => MemoryDetailCubit(repository: sl()));
  sl.registerFactory(() => RecordCubit());
  sl.registerFactory(() => AlbumsCubit(repository: sl()));
  sl.registerFactory(() => FamilyCubit(repository: sl()));
  sl.registerFactory(() => DiscoverCubit(repository: sl()));
  sl.registerFactory(() => NotificationsCubit(repository: sl()));
  sl.registerFactory(() => SettingsCubit(repository: sl()));
}
