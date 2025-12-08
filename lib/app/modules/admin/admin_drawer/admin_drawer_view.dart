// FILE: lib/app/modules/admin/admin_drawer/admin_drawer_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/menu_item_widget.dart';
import 'admin_drawer_controller.dart';

/// Admin drawer view with menu items
class AdminDrawerView extends GetView<AdminDrawerController> {
  const AdminDrawerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer header with logo
              _buildDrawerHeader(),
              
              const Divider(height: 1),
              
              // Menu items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.menuItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.menuItems[index];
                    return Obx(() => MenuItemWidget(
                      icon: item.icon,
                      label: item.label,
                      isSelected: controller.selectedIndex.value == index,
                      onTap: () {
                        controller.selectIndex(index);
                        Navigator.pop(context); // Close drawer on mobile
                      },
                    ));
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.pastelBlue.withOpacity(0.1),
            AppTheme.softGreen.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo with brand image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pastelBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/image/logo_kos_bae.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App name with gradient text effect
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppTheme.pastelBlue, AppTheme.softGreen],
            ).createShader(bounds),
            child: const Text(
              'Kos Bae',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 2),
          
          const Text(
            'Admin Panel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // User email placeholder
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 14, color: AppTheme.pastelBlue),
                const SizedBox(width: 6),
                const Text(
                  'admin@kosbae.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
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
