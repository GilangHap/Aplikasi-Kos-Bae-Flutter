// FILE: lib/app/modules/admin/bills/bill_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/bill_model.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import 'bills_controller.dart';

/// Bill Detail Page - Shows full breakdown, payment history, admin notes
class BillDetailView extends StatefulWidget {
  const BillDetailView({super.key});

  @override
  State<BillDetailView> createState() => _BillDetailViewState();
}

class _BillDetailViewState extends State<BillDetailView> {
  late Bill bill;
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
    bill = Get.arguments as Bill;
    _refreshBillData();
  }

  Future<void> _refreshBillData() async {
    try {
      isLoading.value = true;
      final updated = await _supabase.getBillById(bill.id);
      if (updated != null) {
        setState(() {
          bill = updated;
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAmountCard(),
                  const SizedBox(height: 20),
                  _buildBillInfoCard(),
                  const SizedBox(height: 20),
                  _buildPaymentHistoryCard(),
                  const SizedBox(height: 20),
                  _buildAdminNotesCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _getStatusColor(bill.status),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D3748)),
          onPressed: () => Get.back(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF2D3748)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Get.toNamed('/admin/bills/form', arguments: bill);
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
                case 'mark_paid':
                  _updateStatus('paid');
                  break;
                case 'mark_overdue':
                  _updateStatus('overdue');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFFA9C9FF)),
                    SizedBox(width: 12),
                    Text('Edit Tagihan'),
                  ],
                ),
              ),
              if (bill.status != 'paid')
                const PopupMenuItem(
                  value: 'mark_paid',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFFB9F3CC)),
                      SizedBox(width: 12),
                      Text('Tandai Lunas'),
                    ],
                  ),
                ),
              if (bill.status == 'pending')
                const PopupMenuItem(
                  value: 'mark_overdue',
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Color(0xFFF7C4D4)),
                      SizedBox(width: 12),
                      Text('Tandai Terlambat'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getStatusColor(bill.status),
                _getStatusColor(bill.status).withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(bill.status),
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bill.statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    final progress = bill.amount > 0 ? bill.totalPaid / bill.amount : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total Amount
          Text(
            currencyFormat.format(bill.amount),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bill.typeLabel,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),

          const SizedBox(height: 24),

          // Progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terbayar',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    bill.isFullyPaid
                        ? const Color(0xFFB9F3CC)
                        : const Color(0xFFA9C9FF),
                  ),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAmountLabel(
                    'Terbayar',
                    currencyFormat.format(bill.totalPaid),
                    const Color(0xFFB9F3CC),
                  ),
                  _buildAmountLabel(
                    'Sisa',
                    currencyFormat.format(bill.remainingAmount),
                    bill.remainingAmount > 0
                        ? const Color(0xFFFFD6A5)
                        : const Color(0xFFB9F3CC),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountLabel(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color == const Color(0xFFB9F3CC)
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE65100),
            ),
          ),
        ),
      ],
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
            blurRadius: 15,
            offset: const Offset(0, 4),
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
                child: Icon(Icons.info_outline, color: AppTheme.pastelBlue),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Tagihan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.person, 'Penghuni', bill.tenantName ?? '-'),
          _buildInfoRow(Icons.door_front_door, 'Kamar', bill.roomNumber ?? '-'),
          _buildInfoRow(Icons.category, 'Jenis', bill.typeLabel),
          _buildInfoRow(
            Icons.calendar_month,
            'Periode',
            bill.billingPeriodLabel,
          ),
          _buildInfoRow(Icons.event, 'Jatuh Tempo', bill.formattedDueDate),
          if (bill.notes != null && bill.notes!.isNotEmpty)
            _buildInfoRow(Icons.notes, 'Catatan', bill.notes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB9F3CC).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Riwayat Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAddPaymentSheet(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (bill.payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.payment, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada pembayaran',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ...bill.payments.map((payment) => _buildPaymentItem(payment)),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(
                    payment.status,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getPaymentMethodIcon(payment.method),
                  color: _getPaymentStatusColor(payment.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.formattedAmount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      payment.methodLabel,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPaymentStatusBadge(payment.status),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(payment.paymentDate),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (payment.proofUrl != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showPaymentProof(payment.proofUrl!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, size: 16, color: AppTheme.pastelBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Lihat Bukti Pembayaran',
                      style: TextStyle(
                        color: AppTheme.pastelBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (payment.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectPayment(payment),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _verifyPayment(payment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB9F3CC),
                      foregroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text('Verifikasi'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'verified':
        color = const Color(0xFF2E7D32);
        label = 'Terverifikasi';
        break;
      case 'pending':
        color = const Color(0xFFE65100);
        label = 'Menunggu';
        break;
      case 'rejected':
        color = const Color(0xFFC2185B);
        label = 'Ditolak';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAdminNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD6A5).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.note_alt, color: Color(0xFFE65100)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Catatan Admin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showEditNotesDialog(),
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.grey.shade600,
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
              bill.adminNotes?.isNotEmpty == true
                  ? bill.adminNotes!
                  : 'Belum ada catatan admin',
              style: TextStyle(
                color: bill.adminNotes?.isNotEmpty == true
                    ? const Color(0xFF2D3748)
                    : Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Get.toNamed('/admin/bills/form', arguments: bill),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.pastelBlue),
                  foregroundColor: AppTheme.pastelBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.selectedGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: bill.status != 'paid'
                      ? () => _showAddPaymentSheet()
                      : null,
                  icon: const Icon(Icons.payment),
                  label: Text(
                    bill.status == 'paid' ? 'Sudah Lunas' : 'Catat Pembayaran',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFFB9F3CC);
      case 'verified':
        return const Color(0xFFA9C9FF);
      case 'pending':
        return const Color(0xFFFFD6A5);
      case 'overdue':
        return const Color(0xFFF7C4D4);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.hourglass_empty;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFE65100);
      case 'rejected':
        return const Color(0xFFC2185B);
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
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

  void _showAddPaymentSheet() {
    final amountController = TextEditingController(
      text: bill.remainingAmount.toStringAsFixed(0),
    );
    final notesController = TextEditingController();
    final selectedMethod = 'transfer'.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catat Pembayaran',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Amount
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Pembayaran',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Method
              const Text('Metode Pembayaran'),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    _buildMethodChip('transfer', 'Transfer', selectedMethod),
                    const SizedBox(width: 8),
                    _buildMethodChip('cash', 'Tunai', selectedMethod),
                    const SizedBox(width: 8),
                    _buildMethodChip('ewallet', 'E-Wallet', selectedMethod),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      Get.snackbar('Error', 'Masukkan jumlah yang valid');
                      return;
                    }

                    Get.back();
                    await _addPayment(
                      amount,
                      selectedMethod.value,
                      notesController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB9F3CC),
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simpan Pembayaran'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMethodChip(String value, String label, RxString selected) {
    final isSelected = selected.value == value;
    return InkWell(
      onTap: () => selected.value = value,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _addPayment(double amount, String method, String notes) async {
    try {
      await _supabase.addPayment(
        billId: bill.id,
        amount: amount,
        method: method,
        notes: notes.isNotEmpty ? notes : null,
      );
      await _refreshBillData();
      Get.snackbar(
        'Sukses',
        'Pembayaran berhasil dicatat',
        backgroundColor: const Color(0xFFB9F3CC),
      );
    } catch (e) {
      Get.snackbar('Error', 'Gagal mencatat pembayaran: $e');
    }
  }

  Future<void> _verifyPayment(Payment payment) async {
    try {
      await _supabase.verifyPayment(payment.id);
      await _refreshBillData();
      Get.snackbar('Sukses', 'Pembayaran terverifikasi');
    } catch (e) {
      Get.snackbar('Error', 'Gagal verifikasi: $e');
    }
  }

  Future<void> _rejectPayment(Payment payment) async {
    try {
      await _supabase.rejectPayment(payment.id);
      await _refreshBillData();
      Get.snackbar('Info', 'Pembayaran ditolak');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menolak pembayaran: $e');
    }
  }

  void _showPaymentProof(String url) {
    Get.dialog(
      Dialog(
        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
      ),
    );
  }

  void _showEditNotesDialog() {
    final controller = TextEditingController(text: bill.adminNotes);

    Get.dialog(
      AlertDialog(
        title: const Text('Catatan Admin'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _updateAdminNotes(controller.text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAdminNotes(String notes) async {
    try {
      await _supabase.updateBillAdminNotes(bill.id, notes);
      await _refreshBillData();
      Get.snackbar('Sukses', 'Catatan berhasil disimpan');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan catatan: $e');
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      final controller = Get.find<BillsController>();
      await controller.updateBillStatus(bill, status);
      await _refreshBillData();
      Get.snackbar('Sukses', 'Status berhasil diupdate');
    } catch (e) {
      Get.snackbar('Error', 'Gagal update status: $e');
    }
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Tagihan?'),
          ],
        ),
        content: const Text(
          'Tagihan ini akan dihapus permanen beserta semua riwayat pembayarannya. Lanjutkan?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final controller = Get.find<BillsController>();
              final success = await controller.deleteBill(bill);
              if (success) {
                Get.back();
                Get.snackbar('Sukses', 'Tagihan berhasil dihapus');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
