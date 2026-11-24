/// State of the glasses' audio link (classic Bluetooth: media + calls).
enum GlassesAudioState {
  /// Not checked yet.
  unknown,

  /// The phone has never paired with the glasses' audio side; sound plays on the phone.
  notPaired,

  /// Looking for the glasses and pairing.
  pairing,

  /// Paired, asking the phone to connect audio.
  connecting,

  /// Paired but audio isn't connected right now.
  paired,

  /// Sound plays through the glasses.
  connected,

  /// The last attempt didn't work.
  failed,
}

class GlassesAudioStatus {
  final GlassesAudioState state;
  final String name;
  final String address;
  final bool media;
  final bool calls;

  /// Why the last attempt failed: notFound, pairingRejected, bluetoothOff, unavailable.
  final String failReason;

  const GlassesAudioStatus({
    this.state = GlassesAudioState.unknown,
    this.name = '',
    this.address = '',
    this.media = false,
    this.calls = false,
    this.failReason = '',
  });

  bool get isConnected => state == GlassesAudioState.connected;
  bool get isBusy =>
      state == GlassesAudioState.pairing ||
      state == GlassesAudioState.connecting;
}
