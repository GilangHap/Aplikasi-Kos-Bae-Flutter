// FILE: lib/app/services/auth_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../routes/app_routes.dart';

/// Authentication service for Kos Bae
/// 
/// TODO: Integrate with Supabase Auth
/// - supabase.auth.signInWithPassword()
/// - supabase.auth.signOut()
/// - supabase.auth.onAuthStateChange
/// - Read user role from Supabase storage or user metadata
class AuthService extends GetxService {
  final _client = Get.find<SupabaseService>().client;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString userRole = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      currentUser.value = data.session?.user;
      if (currentUser.value != null) {
        _fetchUserRole();
      } else {
        userRole.value = '';
      }
    });
  }

  /// Initialize service
  Future<AuthService> init() async {
    print('🔐 AuthService initialized');
    currentUser.value = _client.auth.currentUser;
    if (currentUser.value != null) {
      await _fetchUserRole();
    }
    return this;
  }

  /// Initialize service (sync version)
  void initSync() {
    print('🔐 AuthService initialized (sync)');
    currentUser.value = _client.auth.currentUser;
    if (currentUser.value != null) {
      _fetchUserRole();
    }
  }
  
  /// Fetch user role from profiles table
  Future<void> _fetchUserRole() async {
    try {
      final userId = currentUser.value?.id;
      if (userId == null) return;

      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        userRole.value = response['role'] as String;
        print('👤 User role: ${userRole.value}');
      }
    } catch (e) {
      print('❌ Error fetching user role: $e');
    }
  }
  
  /// Get current authenticated user role
  Future<String?> getCurrentUserRole() async {
    if (userRole.value.isEmpty) {
      await _fetchUserRole();
    }
    return userRole.value.isNotEmpty ? userRole.value : null;
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => currentUser.value != null;
  
  /// Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      print('🔑 Signing in: $email');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _fetchUserRole();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Sign in error: $e');
      Get.snackbar(
        'Login Gagal',
        'Email atau password salah',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    print('🚪 Signing out user');
    await _client.auth.signOut();
    userRole.value = '';
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  /// Get current tenant ID if user is a tenant
  Future<String?> getCurrentTenantId() async {
    try {
      final userId = currentUser.value?.id;
      if (userId == null) return null;

      final response = await _client
          .from('tenants')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      print('❌ Error fetching tenant ID: $e');
      return null;
    }
  }
}
