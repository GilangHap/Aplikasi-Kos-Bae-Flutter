import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'home_controller.dart';
import '../tenant_nav/tenant_nav_controller.dart';

/// Minimalist Tenant Dashboard 
class TenantHomeView extends GetView<HomeController> {
  const TenantHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildPremiumLoader();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (controller.tenant.value == null) {
          return Center(
            child: Text(
              'Data penghuni tidak ditemukan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: AppTheme.charcoal.withOpacity(0.6),
              ),
            ),
          );
        }

        // Status-based View
        if (controller.isInactive) {
          return _buildInactiveView();
        } else if (controller.hasLeft) {
          return _buildLeftView();
        } else {
          return _buildMinimalistDashboard();
        }
      }),
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
            'Loading Dashboard...',
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

  Widget _buildMinimalistDashboard() {
    final tenant = controller.tenant.value!;

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppTheme.primaryBlue,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header with gradient
            _buildPremiumHeader(tenant),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Room Status Card - Main Focus
                  _buildRoomStatusCard(tenant),

                  const SizedBox(height: 28),

                  // Quick Stats
                  _buildQuickStats(),

                  const SizedBox(height: 28),

                  // Quick Actions
                  _buildQuickActionsSection(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium header with gradient and clean design
  Widget _buildPremiumHeader(dynamic tenant) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.deepBlue,
            AppTheme.primaryBlue,
            AppTheme.lightBlue.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kos Bae Mini Branding + Notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kos Bae Logo & Name
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/image/logo_new.png',
                              width: 28,
                              height: 28,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.apartment_rounded,
                                size: 28,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KOS BAE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Premium Living',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Notification button
                      _buildNotificationButton(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Greeting section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(DateTime.now().hour),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.cream,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tenant.name.split(' ').first,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('👋', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Room info mini summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            color: AppTheme.cream,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kamar Anda',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tenant.roomNumber ?? 'Belum Ada',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
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
          ),
        ],
      ),
    );
  }

  /// Room Status Card - Main focus
  Widget _buildRoomStatusCard(dynamic tenant) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Penghuni',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contract End Date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.softGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masa Sewa Berakhir',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.charcoal.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tenant.contractEndDate != null
                            ? _formatDate(tenant.contractEndDate!)
                            : '-',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
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

  /// Quick Stats Section
  Widget _buildQuickStats() {
    return Obx(() {
      // Determine bill status color and subtitle
      Color billColor;
      String billSubtitle;

      if (controller.overdueBillsCount.value > 0) {
        billColor = Colors.red;
        billSubtitle = '${controller.overdueBillsCount.value} Terlambat';
      } else if (controller.reminderBillsCount.value > 0) {
        billColor = Colors.amber;
        billSubtitle = 'Segera Jatuh Tempo';
      } else if (controller.unpaidBillsCount.value > 0) {
        billColor = Colors.orange;
        billSubtitle = 'Belum Dibayar';
      } else {
        billColor = Colors.green;
        billSubtitle = 'Semua Lunas';
      }

      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Tagihan',
              value: controller.unpaidBillsCount.value.toString(),
              subtitle: billSubtitle,
              color: billColor,
              onTap: () => Get.find<TenantNavController>().changeIndex(1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.report_problem_rounded,
              label: 'Keluhan',
              value: controller.activeComplaintsCount.value.toString(),
              subtitle: 'Sedang Proses',
              color: AppTheme.primaryBlue,
              onTap: () => Get.find<TenantNavController>().changeIndex(2),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.lightBlue.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flash_on_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Menu Cepat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildMenuButton(
              'Bayar',
              Icons.payment_rounded,
              AppTheme.gold,
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
              AppTheme.primaryBlue,
              () => Get.find<TenantNavController>().changeIndex(3),
            ),
            _buildMenuButton(
              'Bantuan',
              Icons.help_outline_rounded,
              Colors.pink,
              () => controller.showHelpPage(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Terjadi Kesalahan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.charcoal.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
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

  Widget _buildInactiveView() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kos Bae Branding
              _buildKosBaeBranding(),
              const SizedBox(height: 32),
              // Status Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Menunggu Aktivasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Akun Anda sedang dalam proses verifikasi.\nSilakan hubungi admin jika butuh bantuan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.charcoal.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: controller.refreshData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Cek Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftView() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kos Bae Branding
              _buildKosBaeBranding(),
              const SizedBox(height: 32),
              // Goodbye Emoji
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade50, Colors.orange.shade50],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Text('👋', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 24),
              Text(
                'Sampai Jumpa!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Terima kasih telah menjadi bagian dari',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.charcoal.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                ).createShader(bounds),
                child: Text(
                  'Kos Bae',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Semoga sukses selalu! ✨',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.charcoal.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build notification button for header
  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        // Navigate to announcements/notifications page
        Get.toNamed(AppRoutes.TENANT_ANNOUNCEMENTS);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            // Badge indicator for unread notifications
            Positioned(
              right: 0,
              top: 0,
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
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return '☀️ Selamat Pagi';
    if (hour < 15) return '🌤️ Selamat Siang';
    if (hour < 18) return '🌅 Selamat Sore';
    return '🌙 Selamat Malam';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Kos Bae Branding Widget - Premium Design
  Widget _buildKosBaeBranding() {
    return Column(
      children: [
        // Logo Container with gradient border
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.3),
                AppTheme.gold.withOpacity(0.3),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/image/logo_new.png',
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.apartment_rounded,
                  size: 48,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // App Name with gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.deepBlue, AppTheme.primaryBlue],
          ).createShader(bounds),
          child: Text(
            'KOS BAE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Tagline Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.lightBlue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            '✨ Premium Living Management',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
