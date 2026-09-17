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
