// FILE: lib/app/modules/initial/initial_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../routes/app_routes.dart';

/// Initial view - handles role-based routing
class InitialView extends StatefulWidget {
  const InitialView({Key? key}) : super(key: key);

  @override
  State<InitialView> createState() => _InitialViewState();
}

class _InitialViewState extends State<InitialView> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  Future<void> _checkAuthAndRedirect() async {
    // Wait for AuthService to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    final authService = Get.find<AuthService>();
    
    if (!authService.isAuthenticated) {
      Get.offAllNamed(AppRoutes.LOGIN);
      return;
    }
    
    final role = await authService.getCurrentUserRole();
    
    if (role == 'admin') {
      Get.offAllNamed(AppRoutes.ADMIN_LAYOUT);
    } else if (role == 'tenant') {
      Get.offAllNamed(AppRoutes.TENANT_LAYOUT);
    } else {
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
