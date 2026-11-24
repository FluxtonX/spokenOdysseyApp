import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Tracks whether the device can currently reach the internet / backend.
///
/// Pure Dart (no extra native plugin): it opens a short TCP connection to the
/// API host and, if that fails, to a couple of public hosts. The [ApiClient]
/// also feeds it real request outcomes, so going offline is noticed as soon
/// as a request fails and coming back online as soon as one succeeds.
abstract class NetworkInfo {
  bool get isOnline;

  /// Emits only when the online/offline status actually changes.
  Stream<bool> get onStatusChange;

  /// Runs a reachability check right away and returns the result.
  Future<bool> checkNow();

  /// A request got an HTTP response, so the network is reachable.
  void reportReachable();

  /// A request failed without any response (no connection, DNS, timeout).
  void reportUnreachable();

  void dispose();
}

class NetworkProbe {
  final String host;
  final int port;
  const NetworkProbe(this.host, this.port);
}

class NetworkInfoImpl implements NetworkInfo {
  /// Probed first; normally the API server itself.
  final NetworkProbe primaryProbe;

  /// Probed only when [primaryProbe] fails, to tell "server down" apart from
  /// "no internet at all".
  final List<NetworkProbe> fallbackProbes;

  final Duration probeTimeout;
  final Duration onlinePollInterval;
  final Duration offlinePollInterval;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  bool _isForeground = true;
  Timer? _pollTimer;
  Future<bool>? _inFlight;
  AppLifecycleListener? _lifecycleListener;

  NetworkInfoImpl({
    required this.primaryProbe,
    this.fallbackProbes = const [
      NetworkProbe('1.1.1.1', 443),
      NetworkProbe('8.8.8.8', 53),
    ],
    this.probeTimeout = const Duration(seconds: 3),
    this.onlinePollInterval = const Duration(seconds: 60),
    this.offlinePollInterval = const Duration(seconds: 5),
  }) {
    if (kIsWeb) return; // dart:io sockets are not available on web.
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _isForeground = true;
        checkNow();
      },
      onHide: () {
        _isForeground = false;
        _pollTimer?.cancel();
      },
    );
    checkNow();
  }

  /// Builds the primary probe from the API base URL (e.g. http://host:5001/api).
  factory NetworkInfoImpl.forBaseUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    return NetworkInfoImpl(primaryProbe: NetworkProbe(uri.host, port));
  }

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  @override
  Future<bool> checkNow() {
    if (kIsWeb) return Future.value(true);
    return _inFlight ??= _runCheck().whenComplete(() => _inFlight = null);
  }

  @override
  void reportReachable() {
    _setOnline(true);
  }

  @override
  void reportUnreachable() {
    // Confirm with a real probe instead of trusting a single failed request
    // (a slow endpoint can time out while the connection is fine).
    checkNow();
  }

  Future<bool> _runCheck() async {
    var reachable = await _probe(primaryProbe);
    if (!reachable && fallbackProbes.isNotEmpty) {
      reachable = await _anyReachable(fallbackProbes);
    }
    _setOnline(reachable);
    return reachable;
  }

  Future<bool> _probe(NetworkProbe probe) async {
    try {
      final socket = await Socket.connect(
        probe.host,
        probe.port,
        timeout: probeTimeout,
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _anyReachable(List<NetworkProbe> probes) {
    final completer = Completer<bool>();
    var remaining = probes.length;
    for (final probe in probes) {
      _probe(probe).then((ok) {
        if (completer.isCompleted) return;
        remaining--;
        if (ok) {
          completer.complete(true);
        } else if (remaining == 0) {
          completer.complete(false);
        }
      });
    }
    return completer.future;
  }

  void _setOnline(bool online) {
    final changed = online != _isOnline;
    _isOnline = online;
    if (changed) {
      debugPrint(online ? '📶 [Network] Back online' : '📵 [Network] Offline');
      if (!_controller.isClosed) _controller.add(online);
    }
    _schedulePoll();
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    if (!_isForeground || _controller.isClosed) return;
    _pollTimer = Timer(
      _isOnline ? onlinePollInterval : offlinePollInterval,
      checkNow,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _lifecycleListener?.dispose();
    _controller.close();
  }
}
