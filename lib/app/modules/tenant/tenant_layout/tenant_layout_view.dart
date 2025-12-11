import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../tenant_nav/tenant_nav_controller.dart';
import 'tenant_layout_controller.dart';

class TenantLayoutView extends GetView<TenantLayoutController> {
  const TenantLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<TenantNavController>();

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildPremiumLoader();
        }

        return IndexedStack(
          index: navController.currentIndex.value,
          children: navController.pages,
        );
      }),
      bottomNavigationBar: _buildPremiumBottomNavBar(navController),
    );
  }

  /// Premium animated loader
  Widget _buildPremiumLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlue,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/image/logo_new.png',
                  width: 30,
                  height: 30,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.home_rounded,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoal.withOpacity(0.6),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Premium bottom navigation bar with modern design
  Widget _buildPremiumBottomNavBar(TenantNavController navController) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  navController: navController,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Tagihan',
                  index: 1,
                  navController: navController,
                ),
                _buildNavItem(
                  icon: Icons.report_problem_rounded,
                  label: 'Keluhan',
                  index: 2,
                  navController: navController,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  index: 3,
                  navController: navController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Individual navigation item
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required TenantNavController navController,
  }) {
    final isSelected = navController.currentIndex.value == index;

    return Expanded(
      child: InkWell(
        onTap: () => navController.changeIndex(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryBlue.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.charcoal.withOpacity(0.5),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              // Label with animation
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.charcoal.withOpacity(0.6),
                  letterSpacing: isSelected ? 0.3 : 0,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
