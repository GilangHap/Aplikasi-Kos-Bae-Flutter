// FILE: lib/app/modules/admin/bills/bills_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/bill_model.dart';
import '../../../models/tenant_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Bills Management
class BillsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Observables
  final bills = <Bill>[].obs;
  final filteredBills = <Bill>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // Filters & Search
  final selectedStatus = 'all'.obs;
  final selectedType = 'all'.obs;
  final selectedMonth = DateTime.now().obs;
  final searchQuery = ''.obs;
  final sortBy = 'due_date'.obs;

  // Search controller
  final searchController = TextEditingController();

  // Realtime subscription
  RealtimeChannel? _billsChannel;

  // Statistics
  final statistics = <String, dynamic>{
    'total': 0,
    'pending': 0,
    'verified': 0,
    'paid': 0,
    'overdue': 0,
    'totalAmount': 0.0,
    'totalPaid': 0.0,
    'totalPending': 0.0,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBills();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    searchController.dispose();
    _billsChannel?.unsubscribe();
    super.onClose();
  }

  /// Setup realtime subscription
  void _setupRealtimeSubscription() {
    _billsChannel = _supabaseService.client
        .channel('public:bills')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bills',
          callback: (payload) {
            print('🔄 Realtime update for bills: ${payload.eventType}');
            fetchBills();
          },
        )
        .subscribe();

    print('📡 Realtime subscription active for bills');
  }

  /// Fetch all bills from Supabase
  Future<void> fetchBills() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _supabaseService.fetchBills(
        status: selectedStatus.value == 'all' ? null : selectedStatus.value,
        type: selectedType.value == 'all' ? null : selectedType.value,
        month: selectedMonth.value,
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      bills.value = result;
      _applyFilters();
      _calculateStatistics();
    } catch (e) {
      errorMessage.value = 'Gagal memuat data tagihan: ${e.toString()}';
      print('❌ Error fetching bills: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculate statistics
  void _calculateStatistics() {
    final allBills = bills.toList();

    int pending = 0;
    int verified = 0;
    int paid = 0;
    int overdue = 0;
    double totalAmount = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;

    for (final bill in allBills) {
      totalAmount += bill.amount;

      switch (bill.status) {
        case 'pending':
          pending++;
          totalPending += bill.remainingAmount;
          break;
        case 'verified':
          verified++;
          totalPending += bill.remainingAmount;
          break;
        case 'paid':
          paid++;
          totalPaid += bill.amount;
          break;
        case 'overdue':
          overdue++;
          totalPending += bill.remainingAmount;
          break;
      }
    }

    statistics.value = {
      'total': allBills.length,
      'pending': pending,
      'verified': verified,
      'paid': paid,
      'overdue': overdue,
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
    };
  }

  /// Apply local filters
  void _applyFilters() {
    var result = bills.toList();

    // Apply status filter
    if (selectedStatus.value != 'all') {
      result = result.where((b) => b.status == selectedStatus.value).toList();
    }

    // Apply type filter
    if (selectedType.value != 'all') {
      result = result.where((b) => b.type == selectedType.value).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((b) {
        return (b.tenantName?.toLowerCase().contains(query) ?? false) ||
            (b.roomNumber?.toLowerCase().contains(query) ?? false) ||
            b.typeLabel.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    result.sort((a, b) {
      switch (sortBy.value) {
        case 'due_date':
          return a.dueDate.compareTo(b.dueDate);
        case 'amount':
          return b.amount.compareTo(a.amount);
        case 'created_at':
          return b.createdAt.compareTo(a.createdAt);
        case 'status':
          return _getStatusPriority(
            a.status,
          ).compareTo(_getStatusPriority(b.status));
        default:
          return 0;
      }
    });

    filteredBills.value = result;
  }

  int _getStatusPriority(String status) {
    switch (status) {
      case 'overdue':
        return 0;
      case 'pending':
        return 1;
      case 'verified':
        return 2;
      case 'paid':
        return 3;
      default:
        return 4;
    }
  }

  /// Set status filter
  void setStatusFilter(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  /// Set type filter
  void setTypeFilter(String type) {
    selectedType.value = type;
    _applyFilters();
  }

  /// Set month filter
  void setMonthFilter(DateTime month) {
    selectedMonth.value = month;
    fetchBills();
  }

  /// Set sort option
  void setSortBy(String sort) {
    sortBy.value = sort;
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
    await fetchBills();
  }

  /// Generate monthly bills for all active tenants
  Future<bool> generateMonthlyBills() async {
    try {
      isLoading.value = true;

      // Get all active tenants with rooms
      final tenants = await _supabaseService.fetchTenants(status: 'aktif');

      int generated = 0;
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);
      final dueDate = DateTime(now.year, now.month, 10); // Due on 10th

      for (final tenant in tenants) {
        // Skip if tenant doesn't have a contract
        if (tenant.contractId == null) continue;

        // Check if bill already exists for this month
        final existingBill = bills.firstWhereOrNull(
          (b) =>
              b.tenantId == tenant.id &&
              b.type == 'sewa' &&
              b.billingPeriodStart.month == periodStart.month &&
              b.billingPeriodStart.year == periodStart.year,
        );

        if (existingBill != null) continue;

        try {
          // Get contract to find room and price
          final contract = await _supabaseService.client
              .from('contracts')
              .select('room_id, monthly_rent')
              .eq('id', tenant.contractId!)
              .single();

          if (contract['room_id'] == null) continue;

          final roomId = contract['room_id'] as String;
          final monthlyRent = (contract['monthly_rent'] as num).toDouble();

          // Create bill
          final bill = Bill(
            id: '',
            tenantId: tenant.id,
            roomId: roomId,
            amount: monthlyRent,
            type: 'sewa',
            status: 'pending',
            dueDate: dueDate,
            billingPeriodStart: periodStart,
            billingPeriodEnd: periodEnd,
            notes: 'Tagihan sewa bulan ${periodStart.month}/${periodStart.year}',
            createdAt: DateTime.now(),
          );

          await _supabaseService.createBill(bill);
          generated++;
        } catch (e) {
          print('Error creating bill for tenant ${tenant.name}: $e');
          continue;
        }
      }

      await fetchBills();

      Get.snackbar(
        'Sukses',
        'Berhasil generate $generated tagihan bulanan',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: const Color(0xFF2D3748),
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } catch (e) {
      errorMessage.value = 'Gagal generate tagihan: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Gagal generate tagihan: $e',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: const Color(0xFF2D3748),
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete bill
  Future<bool> deleteBill(Bill bill) async {
    try {
      await _supabaseService.deleteBill(bill.id);
      bills.removeWhere((b) => b.id == bill.id);
      _applyFilters();
      _calculateStatistics();
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal menghapus tagihan: ${e.toString()}';
      return false;
    }
  }

  /// Update bill status
  Future<bool> updateBillStatus(Bill bill, String newStatus) async {
    try {
      await _supabaseService.updateBillStatus(bill.id, newStatus);
      await fetchBills();
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal update status: ${e.toString()}';
      return false;
    }
  }

  /// Get bill by ID
  Bill? getBillById(String id) {
    try {
      return bills.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Status filter options
  List<Map<String, String>> get statusOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'pending', 'label': 'Menunggu'},
    {'value': 'verified', 'label': 'Terverifikasi'},
    {'value': 'paid', 'label': 'Lunas'},
    {'value': 'overdue', 'label': 'Terlambat'},
  ];

  /// Type filter options
  List<Map<String, String>> get typeOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'sewa', 'label': 'Sewa'},
    {'value': 'listrik', 'label': 'Listrik'},
    {'value': 'air', 'label': 'Air'},
    {'value': 'deposit', 'label': 'Deposit'},
    {'value': 'denda', 'label': 'Denda'},
    {'value': 'lainnya', 'label': 'Lainnya'},
  ];

  /// Sort options
  List<Map<String, String>> get sortOptions => [
    {'value': 'due_date', 'label': 'Jatuh Tempo'},
    {'value': 'amount', 'label': 'Jumlah'},
    {'value': 'created_at', 'label': 'Terbaru'},
    {'value': 'status', 'label': 'Status'},
  ];
}
