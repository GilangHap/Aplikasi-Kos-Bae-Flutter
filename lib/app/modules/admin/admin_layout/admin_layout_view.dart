// FILE: lib/app/modules/admin/admin_layout/admin_layout_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../admin_drawer/admin_drawer_controller.dart';
import '../admin_drawer/admin_drawer_view.dart';
import '../dashboard/dashboard_view.dart';
import '../rooms_management/rooms_view.dart';
import '../rooms_management/rooms_controller.dart';
import '../rooms_management/rooms_binding.dart';
import '../tenants/tenants_view.dart';
import '../tenants/tenants_controller.dart';
import '../tenants/tenants_binding.dart';
import '../bills/bills_view.dart';
import '../bills/bills_controller.dart';
import '../bills/bills_binding.dart';
import '../payments/payments_view.dart';
import '../payments/payments_controller.dart';
import '../payments/payments_binding.dart';
import '../complaints/complaints_view.dart';
import '../complaints/complaints_controller.dart';
import '../complaints/complaints_binding.dart';
import '../announcements/announcements_view.dart';
import '../announcements/announcements_controller.dart';
import '../announcements/announcements_binding.dart';
import '../contracts/contracts_view.dart';
import '../contracts/contracts_controller.dart';
import '../contracts/contracts_binding.dart';
import '../settings/settings_view.dart';
import '../../../theme/app_theme.dart';
import 'admin_layout_controller.dart';

/// Admin layout with drawer navigation
/// Uses IndexedStack to preserve state when switching between pages
class AdminLayoutView extends GetView<AdminLayoutController> {
  const AdminLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final drawerController = Get.find<AdminDrawerController>();

    // Ensure RoomsController is registered
    if (!Get.isRegistered<RoomsController>()) {
      RoomsBinding().dependencies();
    }

    // Ensure TenantsController is registered
    if (!Get.isRegistered<TenantsController>()) {
      TenantsBinding().dependencies();
    }

    // Ensure BillsController is registered
    if (!Get.isRegistered<BillsController>()) {
      BillsBinding().dependencies();
    }

    // Ensure PaymentsController is registered
    if (!Get.isRegistered<PaymentsController>()) {
      PaymentsBinding().dependencies();
    }

    // Ensure ComplaintsController is registered
    if (!Get.isRegistered<ComplaintsController>()) {
      ComplaintsBinding().dependencies();
    }

    // Ensure AnnouncementsController is registered
    if (!Get.isRegistered<AnnouncementsController>()) {
      AnnouncementsBinding().dependencies();
    }

    // Ensure ContractsController is registered
    if (!Get.isRegistered<ContractsController>()) {
      ContractsBinding().dependencies();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(drawerController),
      drawer: const AdminDrawerView(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return IndexedStack(
          index: drawerController.selectedIndex.value,
          children: const [
            AdminDashboardView(),
            RoomsView(), // Room Management embedded in layout
            TenantsView(), // Tenant Management embedded in layout
            BillsView(), // Bills Management embedded in layout
            AdminPaymentsView(),
            AdminComplaintsView(),
            AdminAnnouncementsView(),
            AdminContractsView(),
            AdminSettingsView(),
          ],
        );
      }),
    );
  }

  /// Build custom AppBar with logo and title
  PreferredSizeWidget _buildAppBar(AdminDrawerController drawerController) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu, size: 20, color: Colors.black87),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          // Brand Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/image/logo_kos_bae.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Obx(() {
            final index = drawerController.selectedIndex.value;
            final title = index < drawerController.menuItems.length
                ? drawerController.menuItems[index].label
                : 'Admin';
            return Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            );
          }),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 20,
              color: Colors.black87,
            ),
          ),
          onPressed: () {
            // TODO: Show notifications
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
