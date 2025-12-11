import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/payment_detail_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Payment Verification
class PaymentsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Observables
  final payments = <PaymentDetail>[].obs;
  final filteredPayments = <PaymentDetail>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // Filters
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;

  // Search controller
  final searchController = TextEditingController();

  // Realtime subscription
  RealtimeChannel? _paymentsChannel;

  // Statistics
  final statistics = <String, dynamic>{
    'total': 0,
    'pending': 0,
    'verified': 0,
    'rejected': 0,
    'totalAmount': 0.0,
    'pendingAmount': 0.0,
    'verifiedAmount': 0.0,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    searchController.dispose();
    _paymentsChannel?.unsubscribe();
    super.onClose();
  }

  /// Setup realtime subscription
  void _setupRealtimeSubscription() {
    _paymentsChannel = _supabaseService.client
        .channel('public:payments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (payload) {
            print('🔄 Payments changed: ${payload.eventType}');
            fetchPayments();
          },
        )
        .subscribe();

    print('📡 Realtime subscription active for payments');
  }

  /// Fetch all payments with bill and tenant details
  Future<void> fetchPayments() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _supabaseService.client
          .from('payments')
          .select('''
            *,
            bills(
              id, amount, type, status, due_date, billing_period_start,
              tenants(id, name, phone, photo_url),
              rooms(id, room_number)
            )
          ''')
          .order('created_at', ascending: false);

      final result = (response as List)
          .map((json) => PaymentDetail.fromJson(json as Map<String, dynamic>))
          .toList();

      payments.value = result;
      _applyFilters();
      _calculateStatistics();
    } catch (e) {
      errorMessage.value = 'Gagal memuat data pembayaran: ${e.toString()}';
      print('❌ Error fetching payments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculate statistics
  void _calculateStatistics() {
    final allPayments = payments.toList();

    int pending = 0;
    int verified = 0;
    int rejected = 0;
    double totalAmount = 0.0;
    double pendingAmount = 0.0;
    double verifiedAmount = 0.0;

    for (final payment in allPayments) {
      totalAmount += payment.amount;

      switch (payment.status) {
        case 'pending':
          pending++;
          pendingAmount += payment.amount;
          break;
        case 'verified':
          verified++;
          verifiedAmount += payment.amount;
          break;
        case 'rejected':
          rejected++;
          break;
      }
    }

    statistics.value = {
      'total': allPayments.length,
      'pending': pending,
      'verified': verified,
      'rejected': rejected,
      'totalAmount': totalAmount,
      'pendingAmount': pendingAmount,
      'verifiedAmount': verifiedAmount,
    };
  }

  /// Apply local filters
  void _applyFilters() {
    var result = payments.toList();

    // Apply status filter
    if (selectedStatus.value != 'all') {
      result = result.where((p) => p.status == selectedStatus.value).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((p) {
        return (p.tenantName?.toLowerCase().contains(q) ?? false) ||
            (p.roomNumber?.toLowerCase().contains(q) ?? false) ||
            p.formattedAmount.toLowerCase().contains(q);
      }).toList();
    }

    filteredPayments.value = result;
  }

  /// Set status filter
  void setStatusFilter(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  /// Handle search
  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFilters();
  }

  /// Refresh data
  Future<void> refreshData() async {
    await fetchPayments();
  }

  /// Verify payment
  Future<bool> verifyPayment(PaymentDetail payment) async {
    try {
      await _supabaseService.verifyPayment(payment.id);
      await fetchPayments();
      Get.snackbar(
        'Sukses',
        'Pembayaran berhasil diverifikasi',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal memverifikasi pembayaran: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Reject payment with reason
  Future<bool> rejectPayment(PaymentDetail payment, String reason) async {
    try {
      await _supabaseService.client
          .from('payments')
          .update({'status': 'rejected', 'rejection_reason': reason})
          .eq('id', payment.id);

      await fetchPayments();
      Get.snackbar(
        'Info',
        'Pembayaran ditolak',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal menolak pembayaran: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Get pending payments count
  int get pendingCount => statistics['pending'] ?? 0;

  /// Status filter options
  List<Map<String, String>> get statusOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'pending', 'label': 'Menunggu'},
    {'value': 'verified', 'label': 'Terverifikasi'},
    {'value': 'rejected', 'label': 'Ditolak'},
  ];
}
