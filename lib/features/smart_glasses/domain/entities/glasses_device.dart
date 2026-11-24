class GlassesDevice {
  final String name;
  final String address;
  final int rssi;
  final bool isConnected;
  final int batteryLevel;
  final bool isCharging;
  final String firmwareVersion;

  const GlassesDevice({
    required this.name,
    required this.address,
    required this.rssi,
    this.isConnected = false,
    this.batteryLevel = 0,
    this.isCharging = false,
    this.firmwareVersion = '',
  });

  /// Name patterns used by HeyCyan / QC smart glasses.
  bool get isLikelyGlasses {
    final n = name.toLowerCase();
    return n.startsWith('o_') ||
        n.startsWith('q_') ||
        n.contains('glass') ||
        n.contains('cyan') ||
        n.contains('odyssey');
  }

  /// Signal strength bucket 0..4 derived from RSSI.
  int get signalLevel {
    if (rssi >= -55) return 4;
    if (rssi >= -67) return 3;
    if (rssi >= -78) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }

  bool get hasBatteryInfo => batteryLevel > 0;

  GlassesDevice copyWith({
    String? name,
    String? address,
    int? rssi,
    bool? isConnected,
    int? batteryLevel,
    bool? isCharging,
    String? firmwareVersion,
  }) {
    return GlassesDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassesDevice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address &&
          rssi == other.rssi &&
          isConnected == other.isConnected &&
          batteryLevel == other.batteryLevel &&
          isCharging == other.isCharging &&
          firmwareVersion == other.firmwareVersion;

  @override
  int get hashCode =>
      name.hashCode ^
      address.hashCode ^
      rssi.hashCode ^
      isConnected.hashCode ^
      batteryLevel.hashCode ^
      isCharging.hashCode ^
      firmwareVersion.hashCode;
}
