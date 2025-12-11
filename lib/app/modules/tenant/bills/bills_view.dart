import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../theme/app_theme.dart';
import '../../../services/app_settings_service.dart';
import 'tenant_bills_controller.dart';

class TenantBillsView extends GetView<TenantBillsController> {
  const TenantBillsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tagihan & Pembayaran'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: AppTheme.pastelBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.pastelBlue,
                tabs: const [
                  Tab(text: 'Tagihan Aktif'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUnpaidBillsList(),
                  _buildHistoryBillsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidBillsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.unpaidBills.isEmpty) {
        return _buildEmptyState('Tidak ada tagihan aktif', Icons.check_circle_outline);
      }

      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: controller.unpaidBills.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final bill = controller.unpaidBills[index];
          return _buildBillCard(bill, isHistory: false);
        },
      );
    });
  }

  Widget _buildHistoryBillsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.historyBills.isEmpty) {
        return _buildEmptyState('Belum ada riwayat pembayaran', Icons.history);
      }

      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: controller.historyBills.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final bill = controller.historyBills[index];
          return _buildBillCard(bill, isHistory: true);
        },
      );
    });
  }

  Widget _buildBillCard(Map<String, dynamic> bill, {required bool isHistory}) {
    final amount = bill['amount'] as num;
    final dueDate = DateTime.parse(bill['due_date']);
    final now = DateTime.now();
    final billStatus = bill['status']?.toString() ?? '';
    final isPaid = isHistory || billStatus == 'paid';
    
    // Get settings from AppSettingsService
    int gracePeriodDays = 3;
    int lateFeePercentage = 5;
    int reminderDaysBefore = 3;
    bool enableLateFee = true;
    bool enableReminders = true;
    
    if (Get.isRegistered<AppSettingsService>()) {
      final settings = Get.find<AppSettingsService>();
      gracePeriodDays = settings.gracePeriodDays.value;
      lateFeePercentage = settings.lateFeePercentage.value;
      reminderDaysBefore = settings.reminderDaysBefore.value;
      enableLateFee = settings.enableLateFee.value;
      enableReminders = settings.enableReminders.value;
    }
    
    // Grace period calculation using settings - ONLY for unpaid bills
    final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays));
    final isInGracePeriod = !isPaid && now.isAfter(dueDate) && now.isBefore(gracePeriodEnd);
    final isOverdue = !isPaid && now.isAfter(gracePeriodEnd);
    final needsReminder = enableReminders && !isPaid && !isOverdue && !isInGracePeriod && 
        now.isAfter(dueDate.subtract(Duration(days: reminderDaysBefore))) && now.isBefore(dueDate);
    final hasPendingPayment = bill['has_pending_payment'] == true;
    
    // Calculate late fee using settings - ONLY for unpaid bills
    final lateFee = (enableLateFee && isOverdue && !isPaid) ? amount * (lateFeePercentage / 100) : 0.0;
    final totalWithLateFee = amount + lateFee;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isHistory) {
      statusColor = AppTheme.softGreen;
      statusText = 'Lunas';
      statusIcon = Icons.check_circle;
    } else if (hasPendingPayment) {
      statusColor = Colors.blue;
      statusText = 'Menunggu Verifikasi';
      statusIcon = Icons.hourglass_top;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Terlambat';
      statusIcon = Icons.warning;
    } else if (isInGracePeriod) {
      statusColor = Colors.orange;
      statusText = 'Masa Tenggang';
      statusIcon = Icons.timer;
    } else if (needsReminder) {
      statusColor = Colors.amber;
      statusText = 'Segera Jatuh Tempo';
      statusIcon = Icons.notifications_active;
    } else {
      statusColor = Colors.orange;
      statusText = 'Belum Dibayar';
      statusIcon = Icons.pending;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isOverdue ? Border.all(color: Colors.red.withOpacity(0.3), width: 1) : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tagihan ${bill['type'].toString().capitalizeFirst}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue || isInGracePeriod ? Colors.red : Colors.grey.shade500,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Late fee info
                if (isOverdue && lateFee > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Denda Keterlambatan: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(lateFee)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalWithLateFee)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Grace period warning
                if (isInGracePeriod) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: Colors.orange.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Masa tenggang berakhir dalam ${gracePeriodEnd.difference(now).inDays + 1} hari. Segera bayar untuk menghindari denda!',
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
                // Reminder
                if (needsReminder) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.amber.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jatuh tempo dalam ${dueDate.difference(now).inDays + 1} hari. Segera lakukan pembayaran!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isHistory && !hasPendingPayment) ...[
            Container(
              height: 1,
              color: Colors.grey.shade100,
            ),
            InkWell(
              onTap: () => _showPaymentSheet(bill),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Center(
                  child: Text(
                    'Bayar Sekarang',
                    style: TextStyle(
                      color: AppTheme.pastelBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(Map<String, dynamic> bill) {
    final amount = bill['amount'];
    final billId = bill['id'];
    final paymentMethod = 'transfer'.obs;
    final selectedImage = Rxn<XFile>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Konfirmasi Pembayaran',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildPaymentDetailRow('Total Tagihan', 
                  NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount)),
              const SizedBox(height: 16),
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Obx(() => Row(
                children: [
                  _buildMethodChip('Transfer Bank', 'transfer', paymentMethod),
                  const SizedBox(width: 12),
                  _buildMethodChip('E-Wallet', 'ewallet', paymentMethod),
                ],
              )),
              const SizedBox(height: 16),
              Obx(() => _buildPaymentInfo(paymentMethod.value)),
              const SizedBox(height: 24),
              const Text(
                'Bukti Pembayaran',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Obx(() => GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    selectedImage.value = image;
                  }
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: selectedImage.value != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb 
                              ? Image.network(selectedImage.value!.path, fit: BoxFit.cover)
                              : Image.file(File(selectedImage.value!.path), fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Upload Foto Bukti',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                ),
              )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () {
                          if (selectedImage.value == null) {
                            Get.snackbar('Error', 'Mohon upload bukti pembayaran');
                            return;
                          }
                          controller.payBill(
                            billId: billId,
                            amount: amount.toDouble(),
                            method: paymentMethod.value,
                            proofFile: selectedImage.value!,
                          ).then((success) {
                            if (success) Get.back();
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: AppTheme.pastelBlue,
                  ),
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Kirim Pembayaran'),
                )),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodChip(String label, String value, RxString selectedValue) {
    final isSelected = selectedValue.value == value;
    return InkWell(
      onTap: () => selectedValue.value = value,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.pastelBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(String method) {
    if (method == 'transfer') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Silakan transfer ke rekening berikut:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Bank_Central_Asia.svg/1200px-Bank_Central_Asia.svg.png',
                  height: 24,
                  errorBuilder: (c, e, s) => const Icon(Icons.account_balance),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BCA 1234567890',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'a.n Kos Bae Official',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan QRIS atau transfer ke E-Wallet:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.qr_code_2, size: 32, color: Colors.orange),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GoPay / OVO / Dana',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '0812-3456-7890 (Kos Bae)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}
