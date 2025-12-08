// FILE: lib/app/middlewares/role_middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

/// Middleware to handle role-based routing
/// 
/// Checks user authentication and role, then redirects to appropriate layout:
/// - Unauthenticated -> LOGIN
/// - Admin role -> ADMIN_LAYOUT
/// - Tenant role -> TENANT_LAYOUT
class RoleMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Get AuthService
    final authService = Get.find<AuthService>();
    
    // This will run synchronously, but getCurrentUserRole is async
    // We'll use a FutureBuilder pattern in InitialView instead
    // For now, just check authentication status
    if (!authService.isAuthenticated && route != AppRoutes.LOGIN) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }
    
    return null;
  }
}
