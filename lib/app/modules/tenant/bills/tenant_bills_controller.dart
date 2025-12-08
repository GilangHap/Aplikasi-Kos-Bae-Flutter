import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';

class TenantBillsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  final _authService = Get.find<AuthService>();

  final unpaidBills = <Map<String, dynamic>>[].obs;
  final historyBills = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBills();
  }

  Future<void> fetchBills() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId == null) {
        errorMessage.value = 'Data penghuni tidak ditemukan';
        return;
      }

      // Fetch bills with payments
      final response = await _supabaseService.client
          .from('bills')
          .select('*, payments(*)')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      final allBills = List<Map<String, dynamic>>.from(response);

      unpaidBills.clear();
      historyBills.clear();

      for (var bill in allBills) {
        final status = bill['status'];
        // Check if there is a pending payment
        final payments = bill['payments'] as List?;
        final hasPendingPayment = payments?.any((p) => p['status'] == 'pending') ?? false;

        // Add 'has_pending_payment' flag to bill for UI
        bill['has_pending_payment'] = hasPendingPayment;

        if (status == 'paid') {
          historyBills.add(bill);
        } else {
          unpaidBills.add(bill);
        }
      }
    } catch (e) {
      errorMessage.value = 'Gagal memuat tagihan: $e';
      print('❌ Error fetching bills: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> payBill({
    required String billId,
    required double amount,
    required String method,
    required XFile proofFile,
    String? notes,
  }) async {
    try {
      isSubmitting.value = true;

      await _supabaseService.submitTenantPayment(
        billId: billId,
        amount: amount,
        method: method,
        proofFile: proofFile,
        notes: notes,
      );

      await fetchBills();
      
      Get.snackbar(
        'Sukses',
        'Pembayaran berhasil dikirim dan sedang menunggu verifikasi',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal mengirim pembayaran: $e',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
