/// Outcome of asking the platform to turn Bluetooth on.
enum BluetoothEnableResult {
  /// Bluetooth was already on.
  alreadyOn,

  /// A system prompt was shown (Android enable dialog / iOS "Turn On
  /// Bluetooth" alert). The real state arrives via `bluetoothStateChanged`.
  prompted,

  /// Bluetooth access is turned off for this app. Only the user can turn it
  /// back on, in the app's Settings page.
  denied,

  /// The device has no Bluetooth radio (e.g. the iOS Simulator).
  unsupported;

  static BluetoothEnableResult fromPlatform(Object? value) => switch (value) {
    'on' => alreadyOn,
    'denied' => denied,
    'unsupported' => unsupported,
    _ => prompted,
  };
}
