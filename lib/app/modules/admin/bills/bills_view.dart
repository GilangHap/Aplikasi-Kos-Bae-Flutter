// FILE: lib/app/modules/admin/bills/bills_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/bill_model.dart';
import '../../../theme/app_theme.dart';
import 'bills_controller.dart';

/// Bills Management View
class BillsView extends GetView<BillsController> {
  const BillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: Obx(() {
        if (controller.isLoading.value && controller.bills.isEmpty) {
          return _buildLoadingShimmer();
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.bills.isEmpty) {
          return _buildErrorState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            slivers: [
              // Premium Header
              SliverToBoxAdapter(child: _buildPremiumHeader()),

              // Statistics Cards
              SliverToBoxAdapter(child: _buildStatisticsCards()),

              // Month Selector
              SliverToBoxAdapter(child: _buildMonthSelector()),

              // Filter & Search Bar
              SliverToBoxAdapter(child: _buildFilterSearchBar()),

              // Bills List
              controller.filteredBills.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildBillCard(controller.filteredBills[index]),
                          childCount: controller.filteredBills.length,
                        ),
                      ),
                    ),
            ],
          ),
        );
      }),
      floatingActionButton: _buildFAB(),
    );
  }

  /// Premium Header
  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepBlue, AppTheme.primaryBlue, AppTheme.lightBlue],
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Tagihan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelola tagihan penghuni kos',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
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
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildHeaderActionButton(
                  icon: Icons.autorenew_rounded,
                  label: 'Generate Tagihan',
                  onTap: () => _showGenerateConfirmDialog(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderActionButton(
                  icon: Icons.build_rounded,
                  label: 'Maintenance',
                  onTap: () => _showMaintenanceConfirmDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showGenerateConfirmDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.autorenew_rounded, color: Colors.green.shade600),
            ),
            const SizedBox(width: 12),
            Text(
              'Generate Tagihan',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Generate tagihan bulan ini untuk semua kontrak aktif yang belum memiliki tagihan?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.generateMonthlyBills();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Generate', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
  
  void _showMaintenanceConfirmDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.build_rounded, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 12),
            Text(
              'Daily Maintenance',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Jalankan maintenance harian:\n\n• Generate tagihan bulan ini\n• Update kontrak yang sudah berakhir\n• Update kontrak yang akan habis',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.runDailyMaintenance();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Jalankan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Statistics cards
  Widget _buildStatisticsCards() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // Amount Statistics - Premium Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.deepBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Obx(
              () => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tagihan',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currencyFormat.format(
                              controller.statistics['totalAmount'] ?? 0,
                            ),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppTheme.gold,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAmountStat(
                            'Terbayar',
                            currencyFormat.format(
                              controller.statistics['totalPaid'] ?? 0,
                            ),
                            const Color(0xFF4CAF50),
                          ),
                        ),
                        Container(width: 1, height: 45, color: Colors.white24),
                        Expanded(
                          child: _buildAmountStat(
                            'Belum Bayar',
                            currencyFormat.format(
                              controller.statistics['totalPending'] ?? 0,
                            ),
                            const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Status Statistics - Horizontal Scroll
          SizedBox(
            height: 120,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard(
                    'Menunggu',
                    '${controller.statistics['pending'] ?? 0}',
                    [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                    Icons.hourglass_empty_rounded,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'Lunas',
                    '${controller.statistics['paid'] ?? 0}',
                    [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                    Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'Terlambat',
                    '${controller.statistics['overdue'] ?? 0}',
                    [const Color(0xFFE91E63), const Color(0xFFF06292)],
                    Icons.warning_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAmountStat(String label, String value, Color accentColor) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    List<Color> gradientColors,
    IconData icon,
  ) {
    return Container(
      width: 115,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Month selector with premium styling
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              final current = controller.selectedMonth.value;
              controller.setMonthFilter(
                DateTime(current.year, current.month - 1, 1),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.charcoal.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: AppTheme.charcoal,
              ),
            ),
          ),
          Obx(
            () => GestureDetector(
              onTap: () => _showMonthPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat(
                        'MMMM yyyy',
                        'id_ID',
                      ).format(controller.selectedMonth.value),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final current = controller.selectedMonth.value;
              controller.setMonthFilter(
                DateTime(current.year, current.month + 1, 1),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.charcoal.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppTheme.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker() async {
    final selected = await showDatePicker(
      context: Get.context!,
      initialDate: controller.selectedMonth.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.charcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected != null) {
      controller.setMonthFilter(DateTime(selected.year, selected.month, 1));
    }
  }

  /// Filter & Search Bar with premium styling
  Widget _buildFilterSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.charcoal.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama penghuni atau kamar...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.charcoal.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.mediumGrey,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTheme.charcoal.withOpacity(0.6),
                              size: 16,
                            ),
                          ),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _buildFilterChip('all', 'Semua', Icons.list_rounded),
                  const SizedBox(width: 10),
                  _buildFilterChip(
                    'pending',
                    'Menunggu',
                    Icons.hourglass_empty_rounded,
                  ),
                  const SizedBox(width: 10),
                  _buildFilterChip('paid', 'Lunas', Icons.check_circle_rounded),
                  const SizedBox(width: 10),
                  _buildFilterChip(
                    'overdue',
                    'Terlambat',
                    Icons.warning_rounded,
                  ),
                  const SizedBox(width: 10),
                  // Sort button
                  GestureDetector(
                    onTap: _showSortBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.mediumGrey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort_rounded,
                            size: 18,
                            color: AppTheme.charcoal.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Urutkan',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.charcoal.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = controller.selectedStatus.value == value;

    return GestureDetector(
      onTap: () => controller.setStatusFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.mediumGrey,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : AppTheme.charcoal.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected
                    ? Colors.white
                    : AppTheme.charcoal.withOpacity(0.7),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bill card with premium styling
  Widget _buildBillCard(Bill bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.charcoal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(bill),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  // Type Icon with gradient
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getTypeColor(bill.type),
                          _getTypeColor(bill.type).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getTypeColor(bill.type).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getTypeIcon(bill.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.tenantName ?? 'Unknown',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.charcoal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Icon(
                                Icons.door_front_door_rounded,
                                size: 12,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Kamar ${bill.roomNumber ?? '-'}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.charcoal.withOpacity(0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  bill.type,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                bill.typeLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  color: _getTypeColor(bill.type),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  _buildStatusBadge(bill.status),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: AppTheme.mediumGrey),
              ),

              // Amount & Due Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jumlah Tagihan',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.charcoal.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            bill.formattedAmount,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Jatuh Tempo',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.charcoal.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 16,
                            color: bill.isOverdue
                                ? const Color(0xFFE91E63)
                                : AppTheme.charcoal.withOpacity(0.6),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            bill.formattedDueDate,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: bill.isOverdue
                                  ? const Color(0xFFE91E63)
                                  : AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // Progress bar for partial payment
              if (bill.totalPaid > 0 && bill.status != 'paid') ...[
                const SizedBox(height: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Terbayar: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(bill.totalPaid)}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.charcoal.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${((bill.totalPaid / bill.amount) * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF4CAF50),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: bill.totalPaid / bill.amount,
                        backgroundColor: AppTheme.mediumGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4CAF50),
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],

              // Days info and Late Fee
              if (bill.status != 'paid') ...[
                const SizedBox(height: 14),
                // Late fee info (if overdue past grace period)
                if (bill.isOverdue && bill.calculateLateFee() > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE91E63).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 20,
                          color: Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Denda Keterlambatan: ${bill.formattedLateFee}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFE91E63),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(bill.totalWithLateFee)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFC2185B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Grace period warning
                if (bill.isInGracePeriod) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Masa tenggang - segera tagih untuk menghindari denda!',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (bill.needsReminder) ...[
                  // Reminder
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${bill.daysUntilDue} hari lagi - perlu pengingat',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.amber.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Regular days info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bill.isOverdue
                          ? const Color(0xFFE91E63).withOpacity(0.1)
                          : AppTheme.softGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          bill.isOverdue
                              ? Icons.warning_rounded
                              : Icons.schedule_rounded,
                          size: 16,
                          color: bill.isOverdue
                              ? const Color(0xFFE91E63)
                              : AppTheme.charcoal.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bill.isOverdue
                              ? 'Terlambat ${-bill.daysUntilDue} hari'
                              : bill.daysUntilDue == 0
                              ? 'Jatuh tempo hari ini'
                              : '${bill.daysUntilDue} hari lagi',
                          style: GoogleFonts.plusJakartaSans(
                            color: bill.isOverdue
                                ? const Color(0xFFE91E63)
                                : AppTheme.charcoal.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'paid':
        bgColor = const Color(0xFF4CAF50).withOpacity(0.15);
        textColor = const Color(0xFF2E7D32);
        label = 'Lunas';
        icon = Icons.check_circle_rounded;
        break;
      case 'verified':
        bgColor = AppTheme.primaryBlue.withOpacity(0.15);
        textColor = AppTheme.primaryBlue;
        label = 'Terverifikasi';
        icon = Icons.verified_rounded;
        break;
      case 'pending':
        bgColor = const Color(0xFFFF9800).withOpacity(0.15);
        textColor = const Color(0xFFE65100);
        label = 'Menunggu';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'overdue':
        bgColor = const Color(0xFFE91E63).withOpacity(0.15);
        textColor = const Color(0xFFE91E63);
        label = 'Terlambat';
        icon = Icons.warning_rounded;
        break;
      default:
        bgColor = AppTheme.mediumGrey;
        textColor = AppTheme.charcoal.withOpacity(0.7);
        label = status;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'sewa':
        return AppTheme.primaryBlue;
      case 'listrik':
        return const Color(0xFFFFB300);
      case 'air':
        return const Color(0xFF00ACC1);
      case 'deposit':
        return const Color(0xFF4CAF50);
      case 'denda':
        return const Color(0xFFE91E63);
      default:
        return AppTheme.charcoal;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sewa':
        return Icons.home_rounded;
      case 'listrik':
        return Icons.bolt_rounded;
      case 'air':
        return Icons.water_drop_rounded;
      case 'deposit':
        return Icons.savings_rounded;
      case 'denda':
        return Icons.gavel_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  /// Loading shimmer
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.mediumGrey,
      highlightColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          height: 170,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.cream.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Belum Ada Tagihan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tagihan akan muncul di sini.\nKlik tombol + untuk menambah tagihan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal.withOpacity(0.6),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToForm(null),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'Tambah Tagihan',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: const Color(0xFFE74C3C),
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: controller.fetchBills,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// FAB with menu
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.deepBlue],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'bills_fab',
        onPressed: () => _navigateToForm(null),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: Text(
          'Tambah',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  void _showSortBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Urutkan Berdasarkan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => Column(
                children: [
                  _buildSortOption(
                    'due_date',
                    'Jatuh Tempo',
                    Icons.event_rounded,
                  ),
                  _buildSortOption(
                    'amount',
                    'Jumlah Tagihan',
                    Icons.payments_rounded,
                  ),
                  _buildSortOption(
                    'created_at',
                    'Terbaru',
                    Icons.access_time_rounded,
                  ),
                  _buildSortOption('status', 'Status', Icons.flag_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = controller.sortBy.value == value;

    return GestureDetector(
      onTap: () {
        controller.setSortBy(value);
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.lightBlue.withOpacity(0.05),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.15)
                    : AppTheme.mediumGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.charcoal.withOpacity(0.5),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.charcoal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showGenerateBillsDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_mode_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Generate Tagihan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda ingin generate tagihan bulanan otomatis untuk semua penghuni aktif?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_rounded,
                    color: Color(0xFFE65100),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tagihan yang sudah ada untuk bulan ini tidak akan di-generate ulang.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.charcoal.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                controller.generateMonthlyBills();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Generate',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Bill bill) {
    Get.toNamed('/admin/bills/detail', arguments: bill);
  }

  void _navigateToForm(Bill? bill) {
    Get.toNamed('/admin/bills/form', arguments: bill);
  }
}
