import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';
import '../core/logger/app_logger.dart';

class RoleMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    // Redirect ke login jika belum authenticated
    if (!authService.isAuthenticated && route != AppRoutes.LOGIN) {
      AppLogger.info('User not authenticated, redirecting to login', tag: 'RoleMiddleware');
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    return null;
  }
}

/// Middleware untuk proteksi route khusus Admin
class AdminMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    // Cek autentikasi
    if (!authService.isAuthenticated) {
      AppLogger.warning('Unauthenticated access to admin route', tag: 'AdminMiddleware');
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    // Cek role admin
    final userRole = authService.userRole.value;
    if (userRole != 'admin') {
      AppLogger.warning('Non-admin user trying to access admin route: $route', tag: 'AdminMiddleware');
      // Redirect ke tenant layout jika bukan admin
      return const RouteSettings(name: AppRoutes.TENANT_LAYOUT);
    }

    return null;
  }
}

/// Middleware untuk proteksi route khusus Tenant
class TenantMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    // Cek autentikasi
    if (!authService.isAuthenticated) {
      AppLogger.warning('Unauthenticated access to tenant route', tag: 'TenantMiddleware');
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    // Cek role tenant
    final userRole = authService.userRole.value;
    if (userRole != 'tenant') {
      AppLogger.warning('Non-tenant user trying to access tenant route: $route', tag: 'TenantMiddleware');
      // Redirect ke admin layout jika bukan tenant
      return const RouteSettings(name: AppRoutes.ADMIN_LAYOUT);
    }

    return null;
  }
}

/// Middleware untuk autentikasi umum (semua role)
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    if (!authService.isAuthenticated) {
      AppLogger.info('Auth required, redirecting to login', tag: 'AuthMiddleware');
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    return null;
  }
}

/// Middleware untuk guest only (login page, register)
class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    // Jika sudah login, redirect ke layout sesuai role
    if (authService.isAuthenticated) {
      final userRole = authService.userRole.value;
      AppLogger.info('Already authenticated user ($userRole) on guest route', tag: 'GuestMiddleware');
      
      if (userRole == 'admin') {
        return const RouteSettings(name: AppRoutes.ADMIN_LAYOUT);
      } else {
        return const RouteSettings(name: AppRoutes.TENANT_LAYOUT);
      }
    }

    return null;
  }
}
