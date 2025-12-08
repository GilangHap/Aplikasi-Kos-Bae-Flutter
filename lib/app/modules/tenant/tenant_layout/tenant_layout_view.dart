// FILE: lib/app/modules/tenant/tenant_layout/tenant_layout_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import '../tenant_nav/tenant_nav_controller.dart';
import 'tenant_layout_controller.dart';

/// Tenant layout with bottom navigation bar
/// Uses IndexedStack to preserve state when switching between tabs
class TenantLayoutView extends GetView<TenantLayoutController> {
  const TenantLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<TenantNavController>();
    
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return IndexedStack(
          index: navController.currentIndex.value,
          children: navController.pages,
        );
      }),
      bottomNavigationBar: _buildBottomNavBar(navController),
    );
  }
  
  Widget _buildBottomNavBar(TenantNavController navController) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        gradient: AppTheme.bottomNavGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                navController: navController,
              ),
              _buildNavItem(
                icon: Icons.receipt_long,
                label: 'Tagihan',
                index: 1,
                navController: navController,
              ),
              _buildNavItem(
                icon: Icons.report_problem,
                label: 'Keluhan',
                index: 2,
                navController: navController,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profil',
                index: 3,
                navController: navController,
              ),
            ],
          ),
        ),
      ),
    ));
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required TenantNavController navController,
  }) {
    final isSelected = navController.currentIndex.value == index;
    
    return InkWell(
      onTap: () => navController.changeIndex(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.selectedGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.softGrey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppTheme.softGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
