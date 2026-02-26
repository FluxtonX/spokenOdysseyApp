import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cache/shared_preferences_helper.dart';
import '../config/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<SharedPrefsHelper>(
        () => SharedPrefsHelper(sharedPreferences: prefs),
  );

  getIt.registerSingleton<LoggerService>(LoggerServiceDevelop());

}
