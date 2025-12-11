import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AppTheme.softGrey,
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

  /// Build premium AppBar with logo and title
  PreferredSizeWidget _buildAppBar(AdminDrawerController drawerController) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 70,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.softGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.mediumGrey.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.menu_rounded,
              size: 22,
              color: AppTheme.charcoal,
            ),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          // Premium Brand Logo with subtle shadow
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/image/logo_new.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Premium Title with accent
          Obx(() {
            final index = drawerController.selectedIndex.value;
            final title = index < drawerController.menuItems.length
                ? drawerController.menuItems[index].label
                : 'Admin';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Premium Panel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      actions: [
        // Premium notification button
        IconButton(
          icon: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.mediumGrey.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: AppTheme.charcoal,
                ),
              ),
              // Badge indicator
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            // TODO: Show notifications
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
