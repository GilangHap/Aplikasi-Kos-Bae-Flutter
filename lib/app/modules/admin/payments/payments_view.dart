// FILE: lib/app/modules/admin/payments/payments_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppTheme.pastelBlue,
      child: CustomScrollView(
        slivers: [
          // Statistics Cards
          SliverToBoxAdapter(child: _buildStatisticsSection(controller)),

          // Search & Filter Bar
          SliverToBoxAdapter(child: _buildSearchAndFilter(controller)),

          // Status Filter Chips
          SliverToBoxAdapter(child: _buildStatusChips(controller)),

          // Payments List
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return SliverFillRemaining(child: _buildErrorState(controller));
            }

            if (controller.filteredPayments.isEmpty) {
              return SliverFillRemaining(child: _buildEmptyState(controller));
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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

      return Container(
        padding: const EdgeInsets.all(16),
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
                      const Color(0xFFFFD6A5).withOpacity(0.3),
                      const Color(0xFFFFD6A5).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD6A5), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD6A5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.pending_actions,
                        color: Colors.black87,
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Butuh verifikasi segera',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.setStatusFilter('pending');
                      },
                      child: const Text('Lihat'),
                    ),
                  ],
                ),
              ),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${stats['total']}',
                    currencyFormat.format(stats['totalAmount']),
                    AppTheme.pastelBlue,
                    Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Terverifikasi',
                    '${stats['verified']}',
                    currencyFormat.format(stats['verifiedAmount']),
                    AppTheme.softGreen,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '${stats['pending']}',
                    currencyFormat.format(stats['pendingAmount']),
                    AppTheme.warmPeach,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Ditolak',
                    '${stats['rejected']}',
                    null,
                    AppTheme.softPink,
                    Icons.cancel,
                  ),
                ),
              ],
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
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(PaymentsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari nama penghuni atau kamar...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: controller.clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips(PaymentsController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.statusOptions.map((option) {
              final isSelected =
                  controller.selectedStatus.value == option['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(option['label']!),
                  selected: isSelected,
                  onSelected: (_) {
                    controller.setStatusFilter(option['value']!);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: _getStatusColor(option['value']!),
                  checkmarkColor: Colors.black87,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.grey.shade600,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? _getStatusColor(option['value']!)
                          : Colors.grey.shade300,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.toNamed(AppRoutes.ADMIN_PAYMENT_DETAIL, arguments: payment);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Tenant info & status
                Row(
                  children: [
                    // Tenant Photo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.pastelBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: payment.tenantPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: payment.tenantPhoto!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Icon(
                                  Icons.person,
                                  color: Colors.black45,
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.black45,
                                ),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.black45),
                    ),
                    const SizedBox(width: 12),
                    // Tenant name & room
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.tenantName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Kamar ${payment.roomNumber ?? '-'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(payment.status),
                  ],
                ),

                const Divider(height: 24),

                // Payment info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nominal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment.formattedAmount,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tagihan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment.billTypeLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          if (payment.billingPeriod != null)
                            Text(
                              payment.billingPeriod!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Upload time & proof indicator
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payment.timeSinceUpload,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    if (payment.hasProof) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pastelBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image,
                              size: 14,
                              color: AppTheme.pastelBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bukti',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.pastelBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMethodIcon(payment.method),
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            payment.methodLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Quick actions for pending
                if (payment.isPending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showRejectDialog(payment, controller);
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Tolak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showVerifyDialog(payment, controller);
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Verifikasi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.softGreen,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'verified':
        color = AppTheme.softGreen;
        label = 'Terverifikasi';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = AppTheme.warmPeach;
        label = 'Menunggu';
        icon = Icons.hourglass_empty;
        break;
      case 'rejected':
        color = AppTheme.softPink;
        label = 'Ditolak';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PaymentsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage.value,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pastelBlue,
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PaymentsController controller) {
    final isFiltered =
        controller.selectedStatus.value != 'all' ||
        controller.searchQuery.value.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off : Icons.payment_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'Tidak Ada Hasil' : 'Belum Ada Pembayaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Pembayaran dari penghuni akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                controller.setStatusFilter('all');
                controller.clearSearch();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Reset Filter'),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppTheme.softGreen;
      case 'pending':
        return AppTheme.warmPeach;
      case 'rejected':
        return AppTheme.softPink;
      default:
        return AppTheme.pastelBlue;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'transfer':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'ewallet':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  void _showVerifyDialog(PaymentDetail payment, PaymentsController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verifikasi Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verifikasi pembayaran dari ${payment.tenantName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.formattedAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        payment.billTypeLabel,
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.verifyPayment(payment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.softGreen,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(PaymentDetail payment, PaymentsController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tolak pembayaran dari ${payment.tenantName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alasan Penolakan *',
                hintText: 'Masukkan alasan penolakan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Error',
                  'Alasan penolakan harus diisi',
                  backgroundColor: AppTheme.softPink,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.softPink,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }
}
