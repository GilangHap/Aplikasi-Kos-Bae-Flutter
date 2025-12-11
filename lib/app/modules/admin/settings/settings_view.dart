// FILE: lib/app/modules/admin/settings/settings_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import 'settings_controller.dart';

/// Admin Settings View with billing configuration
class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    final controller = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverToBoxAdapter(child: _buildPremiumHeader()),

          // Settings content
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingState();
              }
              return _buildSettingsContent(controller);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            AppTheme.lightBlue,
            const Color(0xFF8BC6C8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Konfigurasi tagihan & sistem',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            const SizedBox(height: 16),
            Text(
              'Memuat pengaturan...',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.charcoal.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(SettingsController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Billing Settings Section
          _buildSectionTitle('Pengaturan Tagihan', Icons.receipt_long_rounded),
          const SizedBox(height: 16),
          _buildBillingSettingsCard(controller),

          const SizedBox(height: 24),

          // Late Fee Settings Section
          _buildSectionTitle('Pengaturan Denda', Icons.money_off_rounded),
          const SizedBox(height: 16),
          _buildLateFeeSettingsCard(controller),

          const SizedBox(height: 24),

          // Reminder Settings Section
          _buildSectionTitle('Pengingat', Icons.notifications_rounded),
          const SizedBox(height: 16),
          _buildReminderSettingsCard(controller),

          const SizedBox(height: 24),

          // Save Button
          _buildSaveButton(controller),

          const SizedBox(height: 32),

          // Account Section
          _buildSectionTitle('Akun', Icons.person_rounded),
          const SizedBox(height: 16),
          _buildAccountCard(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
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
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingSettingsCard(SettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Due Date Day
          _buildNumberInputTile(
            icon: Icons.calendar_today_rounded,
            iconColor: AppTheme.primaryBlue,
            title: 'Tanggal Jatuh Tempo',
            subtitle: 'Tanggal tagihan jatuh tempo setiap bulan (1-28)',
            controller: controller.dueDateController,
            suffix: 'setiap bulan',
          ),
          _buildDivider(),
          // Grace Period
          _buildNumberInputTile(
            icon: Icons.timer_rounded,
            iconColor: Colors.orange,
            title: 'Masa Tenggang',
            subtitle: 'Jumlah hari setelah jatuh tempo sebelum dianggap terlambat',
            controller: controller.gracePeriodController,
            suffix: 'hari',
          ),
        ],
      ),
    );
  }

  Widget _buildLateFeeSettingsCard(SettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enable Late Fee
          Obx(() => _buildSwitchTile(
                icon: Icons.money_off_rounded,
                iconColor: Colors.red,
                title: 'Aktifkan Denda Keterlambatan',
                subtitle: 'Denda otomatis untuk pembayaran terlambat',
                value: controller.enableLateFee.value,
                onChanged: (val) => controller.enableLateFee.value = val,
              )),
          Obx(() {
            if (!controller.enableLateFee.value) return const SizedBox.shrink();
            return Column(
              children: [
                _buildDivider(),
                _buildNumberInputTile(
                  icon: Icons.percent_rounded,
                  iconColor: Colors.red.shade400,
                  title: 'Persentase Denda',
                  subtitle: 'Persentase denda dari total tagihan',
                  controller: controller.lateFeeController,
                  suffix: '%',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReminderSettingsCard(SettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enable Reminders
          Obx(() => _buildSwitchTile(
                icon: Icons.notifications_active_rounded,
                iconColor: Colors.blue,
                title: 'Aktifkan Pengingat',
                subtitle: 'Kirim pengingat sebelum jatuh tempo',
                value: controller.enableReminders.value,
                onChanged: (val) => controller.enableReminders.value = val,
              )),
          Obx(() {
            if (!controller.enableReminders.value) return const SizedBox.shrink();
            return Column(
              children: [
                _buildDivider(),
                _buildNumberInputTile(
                  icon: Icons.schedule_rounded,
                  iconColor: Colors.blue.shade400,
                  title: 'Pengingat Sebelum Jatuh Tempo',
                  subtitle: 'Kirim pengingat berapa hari sebelumnya',
                  controller: controller.reminderDaysController,
                  suffix: 'hari sebelum',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logout
          _buildActionTile(
            icon: Icons.logout_rounded,
            iconColor: Colors.red,
            title: 'Keluar',
            subtitle: 'Keluar dari akun admin',
            onTap: () {
              Get.dialog(
                AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Konfirmasi Logout',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    'Apakah Anda yakin ingin keluar?',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.charcoal.withOpacity(0.6),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        final authService = Get.find<AuthService>();
                        await authService.signOut();
                        Get.offAllNamed(AppRoutes.LOGIN);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Keluar',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInputTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.charcoal.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppTheme.softGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                suffix,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.charcoal.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.charcoal.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.charcoal.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.charcoal.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(color: AppTheme.softGrey, height: 1),
    );
  }

  Widget _buildSaveButton(SettingsController controller) {
    return Obx(() => Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue, AppTheme.deepBlue],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: controller.isSaving.value ? null : () => controller.saveSettings(),
            icon: controller.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, color: Colors.white),
            label: Text(
              controller.isSaving.value ? 'Menyimpan...' : 'Simpan Pengaturan',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ));
  }
}
