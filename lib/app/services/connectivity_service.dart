import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../core/logger/app_logger.dart';

/// Service for monitoring network connectivity
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  
  /// Observable for connectivity status
  final isOnline = true.obs;
  
  /// Current connectivity result
  final currentStatus = Rx<List<ConnectivityResult>>([]);
  
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Initialize connectivity service
  Future<ConnectivityService> init() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateStatus(result);
      
      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
      
      AppLogger.success('Connectivity service initialized', tag: 'ConnectivityService');
      return this;
    } catch (e) {
      AppLogger.error('Failed to initialize connectivity service', error: e, tag: 'ConnectivityService');
      rethrow;
    }
  }

  /// Update connectivity status
  void _updateStatus(List<ConnectivityResult> results) {
    currentStatus.value = results;
    
    // Check if any connection is available
    final hasConnection = results.any((result) => 
      result != ConnectivityResult.none
    );
    
    if (isOnline.value != hasConnection) {
      isOnline.value = hasConnection;
      
      if (hasConnection) {
        AppLogger.info('Network connected: ${results.map((r) => r.name).join(', ')}', tag: 'ConnectivityService');
        _onConnected();
      } else {
        AppLogger.warning('Network disconnected', tag: 'ConnectivityService');
        _onDisconnected();
      }
    }
  }

  /// Called when network is connected
  void _onConnected() {
    // Show snackbar notification
    Get.snackbar(
      'Terhubung',
      'Koneksi internet tersedia',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Called when network is disconnected
  void _onDisconnected() {
    // Show snackbar notification
    Get.snackbar(
      'Tidak Ada Koneksi',
      'Menggunakan data cache',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// Check if connected to WiFi
  bool get isWifi => currentStatus.value.contains(ConnectivityResult.wifi);

  /// Check if connected to mobile data
  bool get isMobile => currentStatus.value.contains(ConnectivityResult.mobile);

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
