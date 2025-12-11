import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/menu_item_widget.dart';

/// Controller for admin drawer navigation
class AdminDrawerController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  
  // Menu items for admin drawer
  final List<MenuItem> menuItems = const [
    MenuItem(icon: Icons.dashboard, label: 'Dashboard', route: AppRoutes.ADMIN_DASHBOARD),
    MenuItem(icon: Icons.meeting_room, label: 'Kamar', route: AppRoutes.ADMIN_ROOMS),
    MenuItem(icon: Icons.people, label: 'Penghuni', route: AppRoutes.ADMIN_TENANTS),
    MenuItem(icon: Icons.receipt_long, label: 'Tagihan', route: AppRoutes.ADMIN_BILLING),
    MenuItem(icon: Icons.payment, label: 'Pembayaran', route: AppRoutes.ADMIN_PAYMENTS),
    MenuItem(icon: Icons.report_problem, label: 'Keluhan', route: AppRoutes.ADMIN_COMPLAINTS),
    MenuItem(icon: Icons.campaign, label: 'Pengumuman', route: AppRoutes.ADMIN_ANNOUNCEMENTS),
    MenuItem(icon: Icons.description, label: 'Kontrak', route: AppRoutes.ADMIN_CONTRACTS),
    MenuItem(icon: Icons.settings, label: 'Pengaturan', route: AppRoutes.ADMIN_SETTINGS),
  ];
  
  /// Select menu item - only change index, navigation handled by IndexedStack
  void selectIndex(int index) {
    selectedIndex.value = index;
    // All navigation is handled by IndexedStack in AdminLayoutView
  }
  
  /// Logout user
  Future<void> logout() async {
    final authService = Get.find<AuthService>();
    await authService.signOut();
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
