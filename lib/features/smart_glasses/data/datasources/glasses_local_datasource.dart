import 'package:shared_preferences/shared_preferences.dart';

abstract class GlassesLocalDataSource {
  Future<String?> getSavedDeviceAddress();
  Future<void> saveDeviceAddress(String address);
  Future<void> clearSavedDeviceAddress();
}

class GlassesLocalDataSourceImpl implements GlassesLocalDataSource {
  static const String _keySavedAddress = 'smart_glasses_saved_address';
  final SharedPreferences sharedPreferences;

  GlassesLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<String?> getSavedDeviceAddress() async {
    return sharedPreferences.getString(_keySavedAddress);
  }

  @override
  Future<void> saveDeviceAddress(String address) async {
    await sharedPreferences.setString(_keySavedAddress, address);
  }

  @override
  Future<void> clearSavedDeviceAddress() async {
    await sharedPreferences.remove(_keySavedAddress);
  }
}
