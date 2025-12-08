// FILE: lib/app/bindings/initial_binding.dart
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// Initial binding for global services
/// Executed when app starts
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize SupabaseService first (synchronously)
    // Supabase.instance.client is already available after Supabase.initialize()
    Get.put<SupabaseService>(SupabaseService()..initSync(), permanent: true);
    
    // Initialize AuthService
    Get.put<AuthService>(AuthService()..initSync(), permanent: true);
    
    // Add other global services here if needed
  }
}
