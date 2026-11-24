import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_info.dart';

class ConnectivityState {
  final bool isOnline;
  const ConnectivityState({required this.isOnline});
}

/// App-wide online/offline status for the UI (offline banner, auto-refresh
/// when the connection comes back).
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final NetworkInfo networkInfo;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({required this.networkInfo})
    : super(ConnectivityState(isOnline: networkInfo.isOnline)) {
    _subscription = networkInfo.onStatusChange.listen((online) {
      if (online != state.isOnline) {
        emit(ConnectivityState(isOnline: online));
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
