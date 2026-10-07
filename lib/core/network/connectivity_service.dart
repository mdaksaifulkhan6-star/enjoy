import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Internet Connection Check — realtime stream.
class ConnectivityService {
  ConnectivityService._();

  static final _connectivity = Connectivity();

  static Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// true = online, false = offline
  static Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
}