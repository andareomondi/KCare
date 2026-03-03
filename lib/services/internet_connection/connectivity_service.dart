import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  /* 
 - A singleton service to monitor network connectivity status across the app.
 - It uses the connectivity_plus package to listen for changes in network status and provides a stream to notify listeners about connectivity changes.
 - The service also maintains the current connectivity status for easy access.

  */
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStatusController.stream;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    // User is connected if any result is not "none"
    _isConnected =
        results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}

// Global instance for easy access
final connectivityService = ConnectivityService();
