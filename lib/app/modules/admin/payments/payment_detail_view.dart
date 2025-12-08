// FILE: lib/app/modules/admin/payments/payment_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/payment_detail_model.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'payments_controller.dart';

/// Payment Detail Page - Shows full payment info, proof preview, verification actions
class PaymentDetailView extends StatefulWidget {
  const PaymentDetailView({super.key});

  @override
  State<PaymentDetailView> createState() => _PaymentDetailViewState();
}

class _PaymentDetailViewState extends State<PaymentDetailView> {
  late PaymentDetail payment;
  final _supabase = Get.find<SupabaseService>();
  final RxBool isLoading = false.obs;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    payment = Get.arguments as PaymentDetail;
  }

  Future<void> _refreshPaymentData() async {
    try {
      isLoading.value = true;
      final response = await _supabase.client
          .from('payments')
          .select('''
            *,
            bills(
              id, amount, type, status, due_date, billing_period_start,
              tenants(id, name, phone, photo_url),
              rooms(id, room_number)
            )
          ''')
          .eq('id', payment.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          payment = PaymentDetail.fromJson(response as Map<String, dynamic>);
        });
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPaymentAmountCard(),
                const SizedBox(height: 16),
                _buildTenantInfoCard(),
                const SizedBox(height: 16),
                _buildBillInfoCard(),
                const SizedBox(height: 16),
                if (payment.hasProof) ...[
                  _buildProofCard(),
                  const SizedBox(height: 16),
                ],
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  _buildTenantNotesCard(),
                  const SizedBox(height: 16),
                ],
                if (payment.isRejected && payment.rejectionReason != null) ...[
                  _buildRejectionReasonCard(),
                  const SizedBox(height: 16),
                ],
                _buildPaymentDetailsCard(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: payment.isPending ? _buildActionBar() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: _getStatusColor(payment.status),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getStatusColor(payment.status),
                _getStatusColor(payment.status).withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(payment.status),
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.statusLabel,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              payment.formattedCreatedAt,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Nominal Pembayaran',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            payment.formattedAmount,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(payment.status),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMethodBadge(),
              const SizedBox(width: 12),
              _buildDateBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMethodIcon(payment.method),
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            payment.methodLabel,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            payment.formattedPaymentDate,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Tenant Photo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.pastelBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: payment.tenantPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: payment.tenantPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Icon(Icons.person, color: Colors.black45),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.black45),
                    ),
                  )
                : const Icon(Icons.person, color: Colors.black45, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.tenantName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kamar ${payment.roomNumber ?? '-'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (payment.tenantPhone != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        payment.tenantPhone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (payment.tenantId != null) {
                Get.toNamed(
                  AppRoutes.ADMIN_TENANT_DETAIL,
                  arguments: {'tenantId': payment.tenantId},
                );
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.pastelBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: AppTheme.pastelBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warmPeach.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: AppTheme.warmPeach,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Tagihan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Jenis Tagihan', payment.billTypeLabel),
          if (payment.billingPeriod != null)
            _buildInfoRow('Periode', payment.billingPeriod!),
          _buildInfoRow('Total Tagihan', payment.formattedBillAmount),
          if (payment.billDueDate != null)
            _buildInfoRow(
              'Jatuh Tempo',
              DateFormat('dd MMM yyyy', 'id_ID').format(payment.billDueDate!),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.image, color: AppTheme.pastelBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bukti Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showFullProof(),
                icon: const Icon(Icons.fullscreen, size: 18),
                label: const Text('Lihat'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showFullProof,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: payment.proofUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gagal memuat gambar',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.message, color: AppTheme.softGreen, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Catatan Penghuni',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              payment.notes!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.softPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.softPink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softPink.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cancel, color: Colors.red.shade400, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Alasan Penolakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            payment.rejectionReason!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Detail Pembayaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID Pembayaran', payment.id.substring(0, 8)),
          _buildInfoRow('Tanggal Upload', payment.formattedCreatedAt),
          _buildInfoRow('Metode', payment.methodLabel),
          _buildInfoRow('Status', payment.statusLabel),
          if (payment.formattedVerifiedAt != null)
            _buildInfoRow('Diverifikasi', payment.formattedVerifiedAt!),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showRejectDialog,
                icon: const Icon(Icons.close),
                label: const Text('Tolak'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _showVerifyDialog,
                icon: const Icon(Icons.check),
                label: const Text('Verifikasi Pembayaran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.softGreen,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
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

  void _showFullProof() {
    if (payment.proofUrl == null) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: payment.proofUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerifyDialog() {
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
              try {
                await _supabase.verifyPayment(payment.id);
                await _refreshPaymentData();

                // Refresh parent list if controller exists
                if (Get.isRegistered<PaymentsController>()) {
                  Get.find<PaymentsController>().refreshData();
                }

                Get.snackbar(
                  'Sukses',
                  'Pembayaran berhasil diverifikasi',
                  backgroundColor: AppTheme.softGreen,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Gagal',
                  'Gagal memverifikasi: ${e.toString()}',
                  backgroundColor: AppTheme.softPink,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
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

  void _showRejectDialog() {
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
              try {
                await _supabase.client
                    .from('payments')
                    .update({
                      'status': 'rejected',
                      'rejection_reason': reasonController.text.trim(),
                    })
                    .eq('id', payment.id);

                await _refreshPaymentData();

                // Refresh parent list if controller exists
                if (Get.isRegistered<PaymentsController>()) {
                  Get.find<PaymentsController>().refreshData();
                }

                Get.snackbar(
                  'Info',
                  'Pembayaran ditolak',
                  backgroundColor: AppTheme.softPink,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Gagal',
                  'Gagal menolak: ${e.toString()}',
                  backgroundColor: AppTheme.softPink,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
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
