import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../services/app_settings_service.dart';
import '../core/logger/app_logger.dart';

/// Binding untuk inisialisasi global services saat aplikasi dimulai
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (sync initialization)
    Get.put<SupabaseService>(SupabaseService()..initSync(), permanent: true);
    Get.put<AuthService>(AuthService()..initSync(), permanent: true);
    
    // Additional services will be initialized lazily
    Get.lazyPut<CacheService>(() => CacheService(), fenix: true);
    Get.lazyPut<ConnectivityService>(() => ConnectivityService(), fenix: true);
    
    AppLogger.success('Initial binding complete', tag: 'InitialBinding');
  }
}

/// Async service initializer - call this after app starts
class ServiceInitializer {
  static Future<void> initAsyncServices() async {
    try {
      // Initialize cache service
      final cacheService = CacheService();
      await cacheService.init();
      Get.put<CacheService>(cacheService, permanent: true);
      
      // Initialize connectivity service
      final connectivityService = ConnectivityService();
      await connectivityService.init();
      Get.put<ConnectivityService>(connectivityService, permanent: true);
      
      // Initialize app settings service
      final appSettingsService = AppSettingsService();
      await appSettingsService.init();
      Get.put<AppSettingsService>(appSettingsService, permanent: true);
      
      AppLogger.success('Async services initialized', tag: 'ServiceInitializer');
    } catch (e) {
      AppLogger.error('Failed to initialize async services', error: e, tag: 'ServiceInitializer');
    }
  }
}

