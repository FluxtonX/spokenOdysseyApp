import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:device_preview/device_preview.dart';
import 'package:spokenodyssey/config/app_utils.dart';
import 'package:spokenodyssey/views/splashScreen/splash_screen.dart';
import 'package:spokenodyssey/firebase_options.dart';
import 'config/get_it.dart';
import 'controllers/auth_controller.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();
  await configureDependencies();

  // Initialize AuthController
  Get.put(AuthController(), permanent: true);

  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      debugShowCheckedModeBanner: false,
      title: 'Spoken Odyssey',
      theme: AppTheme.theme,
      home: const SplashScreen(),
      builder: (context, child) {
        CustomScreenUtil.init(context);
        return DevicePreview.appBuilder(context, child);
      },
    );
  }
}
