import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/payment_detail_model.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'payments_controller.dart';

/// Admin Payments Verification View
class AdminPaymentsView extends StatelessWidget {
  const AdminPaymentsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<PaymentsController>()) {
      Get.put(PaymentsController());
    }
    final controller = Get.find<PaymentsController>();

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Premium Header
            SliverToBoxAdapter(child: _buildPremiumHeader(controller)),

            // Statistics Cards
            SliverToBoxAdapter(child: _buildStatisticsSection(controller)),

            // Search & Filter Bar
            SliverToBoxAdapter(child: _buildSearchAndFilter(controller)),

            // Status Filter Chips
            SliverToBoxAdapter(child: _buildStatusChips(controller)),

            // Payments List
            Obx(() {
              if (controller.isLoading.value) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                );
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return SliverFillRemaining(child: _buildErrorState(controller));
              }

              if (controller.filteredPayments.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(controller));
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final payment = controller.filteredPayments[index];
                    return _buildPaymentCard(payment, controller);
                  }, childCount: controller.filteredPayments.length),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(PaymentsController controller) {
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
                          'Verifikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          'Pembayaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${controller.statistics['pending']} menunggu verifikasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
                      Icons.payment_rounded,
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

  Widget _buildStatisticsSection(PaymentsController controller) {
    return Obx(() {
      final stats = controller.statistics;
      final currencyFormat = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending Alert Banner
            if (stats['pending'] > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800).withOpacity(0.15),
                      const Color(0xFFFFB74D).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats['pending']} Pembayaran Menunggu',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Butuh verifikasi segera',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoal.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          controller.setStatusFilter('pending');
                        },
                        child: Text(
                          'Lihat',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Stats Row - Horizontal Scrollable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard(
                    'Total',
                    '${stats['total']}',
                    currencyFormat.format(stats['totalAmount']),
                    AppTheme.primaryBlue,
                    AppTheme.lightBlue,
                    Icons.receipt_long_rounded,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'Terverifikasi',
                    '${stats['verified']}',
                    currencyFormat.format(stats['verifiedAmount']),
                    const Color(0xFF4CAF50),
                    const Color(0xFF81C784),
                    Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'Pending',
                    '${stats['pending']}',
                    currencyFormat.format(stats['pendingAmount']),
                    const Color(0xFFFF9800),
                    const Color(0xFFFFB74D),
                    Icons.hourglass_empty_rounded,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'Ditolak',
                    '${stats['rejected']}',
                    null,
                    const Color(0xFFE91E63),
                    const Color(0xFFF48FB1),
                    Icons.cancel_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String count,
    String? subtitle,
    Color startColor,
    Color endColor,
    IconData icon,
  ) {
    return Container(
      width: 130,
      height: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(PaymentsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
            ),
            Expanded(
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
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.charcoal.withOpacity(0.6),
                    ),
                  ),
                  onPressed: controller.clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips(PaymentsController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.statusOptions.map((option) {
              final isSelected =
                  controller.selectedStatus.value == option['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => controller.setStatusFilter(option['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                _getStatusGradient(option['value']!)[0],
                                _getStatusGradient(option['value']!)[1],
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppTheme.mediumGrey,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _getStatusGradient(
                                  option['value']!,
                                )[0].withOpacity(0.35),
                                blurRadius: 10,
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
                    child: Text(
                      option['label']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.charcoal.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildPaymentCard(
    PaymentDetail payment,
    PaymentsController controller,
  ) {
    const cream = Color(0xFFF5E6D3);
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const deepBlue = Color(0xFF2C3E50);
    const charcoal = Color(0xFF2D3436);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkCream.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Get.toNamed(AppRoutes.ADMIN_PAYMENT_DETAIL, arguments: payment);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Tenant info & status
                Row(
                  children: [
                    // Tenant Photo with premium styling
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cream, darkCream],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: darkCream),
                      ),
                      child: payment.tenantPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: CachedNetworkImage(
                                imageUrl: payment.tenantPhoto!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Icon(
                                  Icons.person_rounded,
                                  color: primaryBlue,
                                  size: 24,
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  color: primaryBlue,
                                  size: 24,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: primaryBlue,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 14),
                    // Tenant name & room
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.tenantName ?? 'Unknown',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cream.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.meeting_room_rounded,
                                  size: 14,
                                  color: primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Kamar ${payment.roomNumber ?? '-'}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: deepBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(payment.status),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        darkCream.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment info with premium styling
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cream.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nominal',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: charcoal.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              payment.formattedAmount,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: deepBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cream.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tagihan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: charcoal.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              payment.billTypeLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: deepBlue,
                              ),
                            ),
                            if (payment.billingPeriod != null)
                              Text(
                                payment.billingPeriod!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: charcoal.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Upload time & proof indicator with premium styling
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: charcoal.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      payment.timeSinceUpload,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: charcoal.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    if (payment.hasProof) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryBlue.withOpacity(0.1),
                              primaryBlue.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_rounded,
                              size: 14,
                              color: primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bukti',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cream.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMethodIcon(payment.method),
                            size: 14,
                            color: charcoal.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payment.methodLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: charcoal.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Quick actions for pending with premium styling
                if (payment.isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE91E63).withOpacity(0.4),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  _showRejectDialog(payment, controller),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: const Color(0xFFE91E63),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tolak',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFE91E63),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () =>
                                  _showVerifyDialog(payment, controller),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verifikasi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    List<Color> gradientColors;
    String label;
    IconData icon;

    switch (status) {
      case 'verified':
        gradientColors = [const Color(0xFF4CAF50), const Color(0xFF81C784)];
        label = 'Terverifikasi';
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        gradientColors = [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
        label = 'Menunggu';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'rejected':
        gradientColors = [const Color(0xFFE91E63), const Color(0xFFF48FB1)];
        label = 'Ditolak';
        icon = Icons.cancel_rounded;
        break;
      default:
        gradientColors = [const Color(0xFF5B8DB8), const Color(0xFF7BA9CC)];
        label = status;
        icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PaymentsController controller) {
    const primaryBlue = Color(0xFF5B8DB8);
    const lightBlue = Color(0xFF7BA9CC);
    const charcoal = Color(0xFF2D3436);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE91E63).withOpacity(0.1),
                    const Color(0xFFF48FB1).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: charcoal.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, lightBlue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: controller.refreshData,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Coba Lagi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(PaymentsController controller) {
    const cream = Color(0xFFF5E6D3);
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const charcoal = Color(0xFF2D3436);

    final isFiltered =
        controller.selectedStatus.value != 'all' ||
        controller.searchQuery.value.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cream, darkCream],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_alt_off_rounded
                    : Icons.payment_rounded,
                size: 56,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFiltered ? 'Tidak Ada Hasil' : 'Belum Ada Pembayaran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Coba ubah filter atau kata kunci pencarian'
                  : 'Pembayaran dari penghuni akan muncul di sini',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: charcoal.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: primaryBlue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      controller.setStatusFilter('all');
                      controller.clearSearch();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_all_rounded, color: primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Reset Filter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'verified':
        return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
      case 'pending':
        return [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
      case 'rejected':
        return [const Color(0xFFE91E63), const Color(0xFFF48FB1)];
      default:
        return [AppTheme.primaryBlue, AppTheme.lightBlue];
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'transfer':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.money_rounded;
      case 'ewallet':
        return Icons.phone_android_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  void _showVerifyDialog(PaymentDetail payment, PaymentsController controller) {
    const cream = Color(0xFFF5E6D3);
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const deepBlue = Color(0xFF2C3E50);
    const charcoal = Color(0xFF2D3436);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Verifikasi Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi pembayaran dari ${payment.tenantName}?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cream, darkCream.withOpacity(0.5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: darkCream),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.receipt_rounded,
                              size: 20,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.formattedAmount,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: deepBlue,
                                ),
                              ),
                              Text(
                                payment.billTypeLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  color: charcoal.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: charcoal.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Get.back(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                'Batal',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: charcoal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              Get.back();
                              await controller.verifyPayment(payment);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                'Verifikasi',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(PaymentDetail payment, PaymentsController controller) {
    const cream = Color(0xFFF5E6D3);
    const darkCream = Color(0xFFE8D4BA);
    const primaryBlue = Color(0xFF5B8DB8);
    const charcoal = Color(0xFF2D3436);
    final reasonController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tolak Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tolak pembayaran dari ${payment.tenantName}?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: charcoal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: cream.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: darkCream),
                      ),
                      child: TextField(
                        controller: reasonController,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: charcoal,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Alasan Penolakan *',
                          labelStyle: GoogleFonts.plusJakartaSans(
                            color: charcoal.withOpacity(0.6),
                          ),
                          hintText: 'Masukkan alasan penolakan...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: charcoal.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: charcoal.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Get.back(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                'Batal',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: charcoal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE91E63).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              if (reasonController.text.trim().isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'Alasan penolakan harus diisi',
                                  backgroundColor: const Color(0xFFF48FB1),
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              Get.back();
                              await controller.rejectPayment(
                                payment,
                                reasonController.text.trim(),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                'Tolak',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
