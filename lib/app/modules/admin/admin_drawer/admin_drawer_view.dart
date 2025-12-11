import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/menu_item_widget.dart';
import 'admin_drawer_controller.dart';

/// Admin drawer view with menu items
class AdminDrawerView extends GetView<AdminDrawerController> {
  const AdminDrawerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.cream.withOpacity(0.3), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer header with logo
              _buildDrawerHeader(),

              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.mediumGrey,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Menu items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.menuItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.menuItems[index];
                    return Obx(
                      () => MenuItemWidget(
                        icon: item.icon,
                        label: item.label,
                        isSelected: controller.selectedIndex.value == index,
                        onTap: () {
                          controller.selectIndex(index);
                          Navigator.pop(context); // Close drawer on mobile
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Logout button
              Padding(
                padding: const EdgeInsets.all(12),
                child: MenuItemWidget(
                  icon: Icons.logout,
                  label: 'Logout',
                  isSelected: false,
                  onTap: () => controller.logout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.05),
            AppTheme.cream.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Logo with shadow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: AppTheme.cream.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Image.asset(
                'assets/image/logo_new.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Premium Brand Name
          Text(
            'Kos Bae',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.charcoal,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 4),

          // Premium Subtitle with gradient accent
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Premium Management',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Premium User Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.mediumGrey, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.gold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'admin@kosbae.com',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.charcoal,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
