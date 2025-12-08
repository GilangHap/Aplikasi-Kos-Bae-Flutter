// FILE: lib/app/modules/admin/dashboard/dashboard_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_pages.dart';
import '../../../routes/app_routes.dart';
import 'dashboard_controller.dart';

/// Modern Admin Dashboard View for Kosan Management
class AdminDashboardView extends GetView<DashboardController> {
  const AdminDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.pastelBlue),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(controller.errorMessage.value),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppTheme.pastelBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildKeyMetricsGrid(),
              const SizedBox(height: 24),
              _buildOccupancyAndRevenue(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildBillsOverview(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }

  /// Header with welcome message and date
  Widget _buildHeader() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.pastelBlue, AppTheme.softGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.pastelBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👋 Selamat Datang, Admin!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '📅 ${dateFormat.format(now)} • ${timeFormat.format(now)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Key metrics in grid layout
  Widget _buildKeyMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: [
        _buildMetricCard(
          title: 'Total Kamar',
          value: '${controller.occupiedRooms.value}/${controller.totalRooms.value}',
          subtitle: 'terisi',
          icon: Icons.meeting_room,
          color: AppTheme.pastelBlue,
          percentage: controller.occupancyRate,
        ),
        _buildMetricCard(
          title: 'Penghuni Aktif',
          value: '${controller.activeTenants.value}',
          subtitle: 'dari ${controller.totalTenants.value} total',
          icon: Icons.people,
          color: AppTheme.softGreen,
        ),
        _buildMetricCard(
          title: 'Pendapatan Bulan Ini',
          value: _formatCurrency(controller.monthlyRevenue.value),
          subtitle: 'sudah terbayar',
          icon: Icons.payments,
          color: AppTheme.warmPeach,
          isRevenue: true,
        ),
        _buildMetricCard(
          title: 'Tagihan Pending',
          value: '${controller.pendingBills.value}',
          subtitle: '${controller.overdueBills.value} terlambat',
          icon: Icons.receipt_long,
          color: controller.overdueBills.value > 0 
              ? AppTheme.softPink 
              : AppTheme.lightYellow,
          hasAlert: controller.overdueBills.value > 0,
        ),
      ],
    );
  }

  /// Metric card widget
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? percentage,
    bool isRevenue = false,
    bool hasAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (hasAlert)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '⚠️',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isRevenue ? 16 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasAlert ? Colors.red : Colors.black45,
                  ),
                ),
              if (percentage != null) ...[
                const SizedBox(height: 6),
                _buildProgressBar(percentage, color),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Progress bar widget
  Widget _buildProgressBar(double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// Occupancy and Revenue visualizations
  Widget _buildOccupancyAndRevenue() {
    return Row(
      children: [
        Expanded(
          child: _buildOccupancyCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildRevenueCard(),
        ),
      ],
    );
  }

  /// Occupancy visualization card
  Widget _buildOccupancyCard() {
    final occupied = controller.occupiedRooms.value;
    final available = controller.availableRooms.value;
    final total = controller.totalRooms.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.pastelBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppTheme.pastelBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Status Kamar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (total > 0)
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: occupied / total,
                        strokeWidth: 12,
                        backgroundColor: AppTheme.softGrey.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.pastelBlue,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${controller.occupancyRate.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.pastelBlue,
                          ),
                        ),
                        const Text(
                          'Terisi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Terisi', occupied, AppTheme.pastelBlue),
              _buildLegendItem('Kosong', available, AppTheme.softGrey),
            ],
          ),
        ],
      ),
    );
  }

  /// Revenue card
  Widget _buildRevenueCard() {
    final collectionRate = controller.collectionRate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warmPeach.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.warmPeach, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pendapatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const Text(
                  'Bulan Ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(controller.monthlyRevenue.value),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warmPeach,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: ${_formatCurrency(controller.totalRevenue.value)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tingkat Penagihan: ${collectionRate.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: collectionRate / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    collectionRate > 80 ? Colors.green : Colors.orange,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Legend item for chart
  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  /// Quick actions panel
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: AppTheme.lightYellow, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionButton(
                label: 'Tambah Penghuni',
                icon: Icons.person_add,
                color: AppTheme.softGreen,
                onTap: () => Get.toNamed(AppRoutes.ADMIN_TENANT_FORM),
              ),
              _buildQuickActionButton(
                label: 'Buat Tagihan',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.warmPeach,
                onTap: () => Get.toNamed(AppRoutes.ADMIN_BILL_FORM),
              ),
              _buildQuickActionButton(
                label: 'Kelola Kamar',
                icon: Icons.meeting_room_rounded,
                color: AppTheme.pastelBlue,
                onTap: () => Get.toNamed(AppRoutes.ADMIN_ROOMS),
              ),
              _buildQuickActionButton(
                label: 'Lihat Keluhan',
                icon: Icons.report_problem_rounded,
                color: controller.activeComplaints.value > 0 
                    ? AppTheme.softPink 
                    : AppTheme.softGrey,
                onTap: () => Get.toNamed(AppRoutes.ADMIN_COMPLAINTS),
                badge: controller.activeComplaints.value > 0 
                    ? controller.activeComplaints.value.toString() 
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Quick action button
  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 20),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bills overview
  Widget _buildBillsOverview() {
    final pending = controller.pendingBills.value;
    final overdue = controller.overdueBills.value;
    final paid = controller.paidBills.value;
    final total = pending + overdue + paid;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.assessment, color: AppTheme.pastelBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Status Tagihan Bulan Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.ADMIN_BILLS),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Lihat Semua'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.pastelBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBillStatusBar(
            label: 'Lunas',
            count: paid,
            total: total,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildBillStatusBar(
            label: 'Pending',
            count: pending,
            total: total,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildBillStatusBar(
            label: 'Terlambat',
            count: overdue,
            total: total,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total belum dibayar:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                _formatCurrency(controller.pendingAmount.value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bill status bar
  Widget _buildBillStatusBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '$count tagihan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// Format currency
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
