import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reactive connectivity stream emitting `true` when the device has no active
/// network transport (`ConnectivityResult.none` only).
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    final initial = await connectivity.checkConnectivity();
    yield initial.every((r) => r == ConnectivityResult.none);
    await for (final results in connectivity.onConnectivityChanged) {
      yield results.every((r) => r == ConnectivityResult.none);
    }
  } on Object {
    yield false;
  }
});
