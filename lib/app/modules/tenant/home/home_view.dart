// FILE: lib/app/modules/tenant/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../../theme/app_theme.dart';
import 'home_controller.dart';
import '../tenant_nav/tenant_nav_controller.dart';

/// Modern Tenant Dashboard
class TenantHomeView extends GetView<HomeController> {
  const TenantHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (controller.tenant.value == null) {
          return const Center(child: Text('Data penghuni tidak ditemukan'));
        }

        // Status-based View
        if (controller.isInactive) {
          return _buildInactiveView();
        } else if (controller.hasLeft) {
          return _buildLeftView();
        } else {
          return _buildModernDashboard(context);
        }
      }),
    );
  }

  Widget _buildModernDashboard(BuildContext context) {
    final tenant = controller.tenant.value!;
    
    return Stack(
      children: [
        // Background Decoration
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.pastelBlue.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Main Content
        CustomScrollView(
          slivers: [
            // App Bar & Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang,',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tenant.name.split(' ').first,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: tenant.photoUrl != null
                                ? NetworkImage(tenant.photoUrl!)
                                : null,
                            backgroundColor: AppTheme.pastelBlue,
                            child: tenant.photoUrl == null
                                ? Text(
                                    tenant.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main Status Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildMainStatusCard(tenant),
              ),
            ),

            // Quick Stats / Alerts
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Tagihan',
                        controller.unpaidBillsCount.value.toString(),
                        'Belum Dibayar',
                        Icons.receipt_long,
                        controller.unpaidBillsCount.value > 0 
                            ? Colors.orange 
                            : AppTheme.softGreen,
                        () => Get.find<TenantNavController>().changeIndex(1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Keluhan',
                        controller.activeComplaintsCount.value.toString(),
                        'Sedang Proses',
                        Icons.report_problem_outlined,
                        AppTheme.pastelBlue,
                        () => Get.find<TenantNavController>().changeIndex(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menu Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildMenuButton(
                          'Bayar',
                          Icons.payment_rounded,
                          AppTheme.softGreen,
                          () => Get.find<TenantNavController>().changeIndex(1),
                        ),
                        _buildMenuButton(
                          'Lapor',
                          Icons.build_rounded,
                          Colors.orange,
                          () => Get.find<TenantNavController>().changeIndex(2),
                        ),
                        _buildMenuButton(
                          'Profil',
                          Icons.person_rounded,
                          AppTheme.pastelBlue,
                          () => Get.find<TenantNavController>().changeIndex(3),
                        ),
                        _buildMenuButton(
                          'Bantuan',
                          Icons.help_outline_rounded,
                          AppTheme.softPink,
                          () => controller.showHelpPage(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ],
    );
  }

  Widget _buildMainStatusCard(dynamic tenant) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B8EFF), Color(0xFF4A6FFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6FFF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Penghuni Aktif',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.apartment, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kamar Anda',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tenant.roomNumber ?? 'Belum Ada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Masa Sewa Berakhir',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              tenant.contractEndDate != null
                                  ? _formatDate(tenant.contractEndDate!)
                                  : '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 80,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Menunggu Aktivasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Akun Anda sedang dalam proses verifikasi. Silakan hubungi admin jika butuh bantuan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Cek Status'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                size: 80,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sampai Jumpa!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Terima kasih telah menjadi bagian dari Kos Bae. Semoga sukses selalu!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
