// FILE: lib/app/modules/admin/bills/bills_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/bill_model.dart';
import '../../../theme/app_theme.dart';
import 'bills_controller.dart';

/// Bills Management View
class BillsView extends GetView<BillsController> {
  const BillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          color: AppTheme.pastelBlue,
          child: CustomScrollView(
            slivers: [
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

  /// Statistics cards
  Widget _buildStatisticsCards() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // Amount Statistics
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA9C9FF), Color(0xFFB9F3CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA9C9FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
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
                          const Text(
                            'Total Tagihan',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(
                              controller.statistics['totalAmount'] ?? 0,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountStat(
                          'Terbayar',
                          currencyFormat.format(
                            controller.statistics['totalPaid'] ?? 0,
                          ),
                          Colors.white,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white30),
                      Expanded(
                        child: _buildAmountStat(
                          'Belum Bayar',
                          currencyFormat.format(
                            controller.statistics['totalPending'] ?? 0,
                          ),
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status Statistics
          Row(
            children: [
              _buildStatCard(
                'Menunggu',
                '${controller.statistics['pending'] ?? 0}',
                const Color(0xFFFFD6A5),
                Icons.hourglass_empty,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Lunas',
                '${controller.statistics['paid'] ?? 0}',
                const Color(0xFFB9F3CC),
                Icons.check_circle,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Terlambat',
                '${controller.statistics['overdue'] ?? 0}',
                const Color(0xFFF7C4D4),
                Icons.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAmountStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Month selector
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final current = controller.selectedMonth.value;
              controller.setMonthFilter(
                DateTime(current.year, current.month - 1, 1),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left, size: 20),
            ),
          ),
          Obx(
            () => GestureDetector(
              onTap: () => _showMonthPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.selectedGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'MMMM yyyy',
                        'id_ID',
                      ).format(controller.selectedMonth.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              final current = controller.selectedMonth.value;
              controller.setMonthFilter(
                DateTime(current.year, current.month + 1, 1),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_right, size: 20),
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
    );
    if (selected != null) {
      controller.setMonthFilter(DateTime(selected.year, selected.month, 1));
    }
  }

  /// Filter & Search Bar
  Widget _buildFilterSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama penghuni atau kamar...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: [
                  _buildFilterChip('all', 'Semua', Icons.list),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'pending',
                    'Menunggu',
                    Icons.hourglass_empty,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip('paid', 'Lunas', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildFilterChip('overdue', 'Terlambat', Icons.warning),
                  const SizedBox(width: 8),
                  // Sort button
                  InkWell(
                    onTap: _showSortBottomSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sort,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Urutkan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
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

    return InkWell(
      onTap: () => controller.setStatusFilter(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.selectedGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bill card
  Widget _buildBillCard(Bill bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(bill),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  // Type Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTypeColor(bill.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getTypeIcon(bill.type),
                      color: _getTypeColor(bill.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.tenantName ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.door_front_door,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Kamar ${bill.roomNumber ?? '-'}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(
                                  bill.type,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bill.typeLabel,
                                style: TextStyle(
                                  color: _getTypeColor(bill.type),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  _buildStatusBadge(bill.status),
                ],
              ),

              const Divider(height: 24),

              // Amount & Due Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah Tagihan',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bill.formattedAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Jatuh Tempo',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: bill.isOverdue
                                ? const Color(0xFFC2185B)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bill.formattedDueDate,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: bill.isOverdue
                                  ? const Color(0xFFC2185B)
                                  : const Color(0xFF2D3748),
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
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terbayar: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(bill.totalPaid)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${((bill.totalPaid / bill.amount) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: bill.totalPaid / bill.amount,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFB9F3CC),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],

              // Days info
              if (bill.status != 'paid') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bill.isOverdue
                        ? const Color(0xFFFCE4EC)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        bill.isOverdue ? Icons.warning : Icons.schedule,
                        size: 16,
                        color: bill.isOverdue
                            ? const Color(0xFFC2185B)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        bill.isOverdue
                            ? 'Terlambat ${-bill.daysUntilDue} hari'
                            : bill.daysUntilDue == 0
                            ? 'Jatuh tempo hari ini'
                            : '${bill.daysUntilDue} hari lagi',
                        style: TextStyle(
                          color: bill.isOverdue
                              ? const Color(0xFFC2185B)
                              : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Lunas';
        icon = Icons.check_circle;
        break;
      case 'verified':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        label = 'Terverifikasi';
        icon = Icons.verified;
        break;
      case 'pending':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'Menunggu';
        icon = Icons.hourglass_empty;
        break;
      case 'overdue':
        bgColor = const Color(0xFFFCE4EC);
        textColor = const Color(0xFFC2185B);
        label = 'Terlambat';
        icon = Icons.warning;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'sewa':
        return const Color(0xFFA9C9FF);
      case 'listrik':
        return const Color(0xFFFFD93D);
      case 'air':
        return const Color(0xFF6ECFF6);
      case 'deposit':
        return const Color(0xFFB9F3CC);
      case 'denda':
        return const Color(0xFFF7C4D4);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sewa':
        return Icons.home;
      case 'listrik':
        return Icons.bolt;
      case 'air':
        return Icons.water_drop;
      case 'deposit':
        return Icons.savings;
      case 'denda':
        return Icons.gavel;
      default:
        return Icons.receipt;
    }
  }

  /// Loading shimmer
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.pastelBlue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppTheme.pastelBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Tagihan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tagihan akan muncul di sini.\nKlik tombol + untuk menambah tagihan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tagihan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pastelBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.fetchBills,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  /// FAB with menu
  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Generate Bills Button
        FloatingActionButton.small(
          heroTag: 'generate_bills_fab',
          onPressed: () => _showGenerateBillsDialog(),
          backgroundColor: const Color(0xFFB9F3CC),
          child: const Icon(Icons.auto_mode, color: Color(0xFF2E7D32)),
        ),
        const SizedBox(height: 12),
        // Add Bill Button
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA9C9FF), Color(0xFFB9F3CC)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA9C9FF).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'bills_fab',
            onPressed: () => _navigateToForm(null),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Tambah',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  void _showSortBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Urutkan Berdasarkan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSortOption('due_date', 'Jatuh Tempo', Icons.event),
            _buildSortOption('amount', 'Jumlah Tagihan', Icons.payments),
            _buildSortOption('created_at', 'Terbaru', Icons.access_time),
            _buildSortOption('status', 'Status', Icons.flag),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = controller.sortBy.value == value;

    return InkWell(
      onTap: () {
        controller.setSortBy(value);
        Get.back();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pastelBlue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.pastelBlue),
          ],
        ),
      ),
    );
  }

  void _showGenerateBillsDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFB9F3CC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_mode, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            const Text('Generate Tagihan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda ingin generate tagihan bulanan otomatis untuk semua penghuni aktif?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tagihan yang sudah ada untuk bulan ini tidak akan di-generate ulang.',
                      style: TextStyle(
                        fontSize: 12,
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
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.generateMonthlyBills();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB9F3CC),
              foregroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Generate'),
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
