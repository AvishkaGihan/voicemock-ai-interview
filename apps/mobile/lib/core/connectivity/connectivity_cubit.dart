import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicemock/core/connectivity/connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit({required Connectivity connectivity})
    : _connectivity = connectivity,
      super(const ConnectivityInitial());

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Check current connectivity status once
  Future<void> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _emitStateFromResults(results);
  }

  /// Start listening to connectivity changes
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _emitStateFromResults,
    );
  }

  /// Stop listening to connectivity changes
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _emitStateFromResults(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    emit(
      isConnected ? const ConnectivityOnline() : const ConnectivityOffline(),
    );
  }

  @override
  Future<void> close() async {
    await stopListening();
    return super.close();
  }
}
