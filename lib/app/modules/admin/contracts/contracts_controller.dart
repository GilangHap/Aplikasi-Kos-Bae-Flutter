// FILE: lib/app/modules/admin/contracts/contracts_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/contract_model.dart';
import '../../../models/tenant_model.dart';
import '../../../models/room_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Contracts Management
class ContractsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Observables
  final contracts = <Contract>[].obs;
  final filteredContracts = <Contract>[].obs;
  final tenants = <Tenant>[].obs;
  final rooms = <Room>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  // Filters
  final selectedFilter = 'all'.obs; // all, aktif, akan_habis, berakhir
  final searchQuery = ''.obs;

  // Search controller
  final searchController = TextEditingController();

  // Realtime subscription
  RealtimeChannel? _contractsChannel;

  // Statistics
  final statistics = <String, dynamic>{
    'total': 0,
    'aktif': 0,
    'akanHabis': 0,
    'berakhir': 0,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchContracts();
    fetchTenants();
    fetchRooms();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    searchController.dispose();
    _contractsChannel?.unsubscribe();
    super.onClose();
  }

  /// Setup realtime subscription
  void _setupRealtimeSubscription() {
    _contractsChannel = _supabaseService.client
        .channel('public:contracts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'contracts',
          callback: (payload) {
            print('🔄 Contracts changed: ${payload.eventType}');
            fetchContracts();
          },
        )
        .subscribe();

    print('📡 Realtime subscription active for contracts');
  }

  /// Fetch all contracts
  Future<void> fetchContracts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📥 Fetching contracts...');

      // Simplified query to avoid embedding conflicts
      final response = await _supabaseService.client
          .from('contracts')
          .select('''
            *,
            tenants:tenant_id(id, name, phone, photo_url),
            rooms:room_id(id, room_number, price)
          ''')
          .order('created_at', ascending: false);

      print('📦 Response: $response');

      final result = (response as List)
          .map((json) => Contract.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update status based on dates
      for (var i = 0; i < result.length; i++) {
        final contract = result[i];
        final calculatedStatus = contract.calculatedStatus;
        if (contract.status != calculatedStatus) {
          // Update status in database
          await _updateContractStatus(contract.id, calculatedStatus);
          result[i] = contract.copyWith(status: calculatedStatus);
        }
      }

      print('✅ Parsed ${result.length} contracts');

      contracts.value = result;
      _applyFilters();
      _calculateStatistics();
    } catch (e, stackTrace) {
      errorMessage.value = 'Gagal memuat data kontrak: ${e.toString()}';
      print('❌ Error fetching contracts: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update contract status silently
  Future<void> _updateContractStatus(String id, String status) async {
    try {
      await _supabaseService.client
          .from('contracts')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      print('❌ Error updating contract status: $e');
    }
  }

  /// Fetch tenants for dropdown
  Future<void> fetchTenants() async {
    try {
      final result = await _supabaseService.fetchTenants(status: 'aktif');
      tenants.value = result;
    } catch (e) {
      print('❌ Error fetching tenants: $e');
    }
  }

  /// Fetch rooms for dropdown (only empty rooms available for contract)
  Future<void> fetchRooms() async {
    try {
      // Only fetch empty rooms for contract assignment
      final result = await _supabaseService.getAvailableRooms();
      rooms.value = result;
    } catch (e) {
      print('❌ Error fetching rooms: $e');
    }
  }

  /// Calculate statistics
  void _calculateStatistics() {
    final allContracts = contracts.toList();

    int aktif = 0;
    int akanHabis = 0;
    int berakhir = 0;

    for (final contract in allContracts) {
      switch (contract.status) {
        case 'aktif':
          aktif++;
          break;
        case 'akan_habis':
          akanHabis++;
          break;
        case 'berakhir':
          berakhir++;
          break;
      }
    }

    statistics.value = {
      'total': allContracts.length,
      'aktif': aktif,
      'akanHabis': akanHabis,
      'berakhir': berakhir,
    };
  }

  /// Apply local filters
  void _applyFilters() {
    var result = contracts.toList();

    // Apply filter
    if (selectedFilter.value != 'all') {
      result = result.where((c) => c.status == selectedFilter.value).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((c) {
        return (c.tenantName?.toLowerCase().contains(q) ?? false) ||
            (c.roomNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    filteredContracts.value = result;
  }

  /// Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
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

  /// Clear all filters
  void clearFilters() {
    selectedFilter.value = 'all';
    clearSearch();
  }

  /// Refresh data
  Future<void> refreshData() async {
    await fetchContracts();
  }

  /// Create new contract and generate monthly bills
  Future<bool> createContract({
    required String tenantId,
    required String roomId,
    required double monthlyRent,
    required DateTime startDate,
    required DateTime endDate,
    XFile? document,
    String? notes,
  }) async {
    try {
      isSaving.value = true;

      // Validate room is empty before creating contract
      final room = await _supabaseService.getRoomById(roomId);
      if (room == null) {
        throw Exception('Kamar tidak ditemukan');
      }
      if (room.status != 'kosong') {
        throw Exception(
          'Kamar sudah terisi. Hanya kamar kosong yang bisa dibuat kontrak.',
        );
      }

      // Upload document if provided
      String? documentUrl;
      if (document != null) {
        documentUrl = await _supabaseService.uploadFile(
          document,
          folder: 'contracts',
        );
      }

      // Calculate initial status
      String status = 'aktif';
      final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 30) {
        status = 'akan_habis';
      }

      // Insert contract
      final contractResponse = await _supabaseService.client
          .from('contracts')
          .insert({
            'tenant_id': tenantId,
            'room_id': roomId,
            'monthly_rent': monthlyRent,
            'start_date': startDate.toIso8601String().split('T').first,
            'end_date': endDate.toIso8601String().split('T').first,
            'document_url': documentUrl,
            'status': status,
            'notes': notes,
            'created_at': DateTime.now().toIso8601String(),
            'created_by': _supabaseService.auth.currentUser?.id,
          })
          .select()
          .single();

      final contractId = contractResponse['id'] as String;

      // Update room status to 'terisi'
      final tenant = await _supabaseService.getTenantById(tenantId);
      await _supabaseService.client
          .from('rooms')
          .update({
            'status': 'terisi',
            'current_tenant_name': tenant?.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', roomId);

      // Generate monthly bills
      await _generateMonthlyBills(
        contractId: contractId,
        tenantId: tenantId,
        roomId: roomId,
        monthlyRent: monthlyRent,
        startDate: startDate,
        endDate: endDate,
      );

      await fetchContracts();
      await fetchRooms(); // Refresh rooms list

      Get.snackbar(
        'Sukses',
        'Kontrak berhasil dibuat dan tagihan bulanan telah digenerate',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal membuat kontrak: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Generate monthly bills for a contract
  Future<void> _generateMonthlyBills({
    required String contractId,
    required String tenantId,
    required String roomId,
    required double monthlyRent,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Calculate number of months
      DateTime current = DateTime(startDate.year, startDate.month, 1);
      final end = DateTime(endDate.year, endDate.month, 1);

      List<Map<String, dynamic>> bills = [];

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        // Billing period
        final periodStart = DateTime(current.year, current.month, 1);
        final periodEnd = DateTime(
          current.year,
          current.month + 1,
          0,
        ); // Last day of month

        // Due date is the 10th of the month
        final dueDate = DateTime(current.year, current.month, 10);

        bills.add({
          'tenant_id': tenantId,
          'room_id': roomId,
          'contract_id': contractId,
          'amount': monthlyRent,
          'type': 'sewa',
          'status': 'pending',
          'due_date': dueDate.toIso8601String().split('T').first,
          'billing_period_start': periodStart
              .toIso8601String()
              .split('T')
              .first,
          'billing_period_end': periodEnd.toIso8601String().split('T').first,
          'notes':
              'Tagihan sewa bulan ${_getMonthName(current.month)} ${current.year}',
          'created_at': DateTime.now().toIso8601String(),
          'created_by': _supabaseService.auth.currentUser?.id,
        });

        // Move to next month
        current = DateTime(current.year, current.month + 1, 1);
      }

      // Batch insert bills
      if (bills.isNotEmpty) {
        await _supabaseService.client.from('bills').insert(bills);
        print('✅ Generated ${bills.length} monthly bills');
      }
    } catch (e) {
      print('❌ Error generating monthly bills: $e');
      rethrow;
    }
  }

  /// Get month name in Indonesian
  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  /// Renew contract
  Future<bool> renewContract({
    required Contract oldContract,
    required DateTime newEndDate,
    XFile? newDocument,
    String? notes,
  }) async {
    try {
      isSaving.value = true;

      // Upload new document if provided
      String? documentUrl = oldContract.documentUrl;
      if (newDocument != null) {
        documentUrl = await _supabaseService.uploadFile(
          newDocument,
          folder: 'contracts',
        );
      }

      // Mark old contract as ended
      await _supabaseService.client
          .from('contracts')
          .update({
            'status': 'berakhir',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', oldContract.id);

      // New start date is the day after old end date
      final newStartDate = oldContract.endDate.add(const Duration(days: 1));

      // Calculate new status
      String status = 'aktif';
      final daysUntilExpiry = newEndDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 30) {
        status = 'akan_habis';
      }

      // Insert new contract
      final contractResponse = await _supabaseService.client
          .from('contracts')
          .insert({
            'tenant_id': oldContract.tenantId,
            'room_id': oldContract.roomId,
            'monthly_rent': oldContract.monthlyRent,
            'start_date': newStartDate.toIso8601String().split('T').first,
            'end_date': newEndDate.toIso8601String().split('T').first,
            'document_url': documentUrl,
            'status': status,
            'notes':
                notes ??
                'Perpanjangan kontrak dari ${oldContract.formattedStartDate}',
            'parent_contract_id': oldContract.id,
            'created_at': DateTime.now().toIso8601String(),
            'created_by': _supabaseService.auth.currentUser?.id,
          })
          .select()
          .single();

      final contractId = contractResponse['id'] as String;

      // Generate new monthly bills
      await _generateMonthlyBills(
        contractId: contractId,
        tenantId: oldContract.tenantId,
        roomId: oldContract.roomId!,
        monthlyRent: oldContract.monthlyRent,
        startDate: newStartDate,
        endDate: newEndDate,
      );

      await fetchContracts();

      Get.snackbar(
        'Sukses',
        'Kontrak berhasil diperpanjang dan tagihan bulanan telah digenerate',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal memperpanjang kontrak: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Update contract document
  Future<bool> updateContractDocument({
    required String contractId,
    required XFile newDocument,
  }) async {
    try {
      isSaving.value = true;

      // Upload new document
      final documentUrl = await _supabaseService.uploadFile(
        newDocument,
        folder: 'contracts',
      );

      // Update contract
      await _supabaseService.client
          .from('contracts')
          .update({
            'document_url': documentUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', contractId);

      await fetchContracts();

      Get.snackbar(
        'Sukses',
        'Dokumen kontrak berhasil diperbarui',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal memperbarui dokumen: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Delete contract
  Future<bool> deleteContract(Contract contract) async {
    try {
      // Delete document from storage if exists
      if (contract.hasDocument) {
        await _supabaseService.deleteFile(contract.documentUrl!);
      }

      // Update room status back to 'kosong' if room exists
      if (contract.roomId != null) {
        await _supabaseService.client
            .from('rooms')
            .update({
              'status': 'kosong',
              'current_tenant_name': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', contract.roomId!);
      }

      // Delete contract (bills with contract_id will be cascade deleted or kept based on FK)
      await _supabaseService.client
          .from('contracts')
          .delete()
          .eq('id', contract.id);

      await fetchContracts();

      Get.snackbar(
        'Sukses',
        'Kontrak berhasil dihapus dan kamar dikembalikan ke status kosong',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal menghapus kontrak: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Get contract by ID
  Contract? getContractById(String id) {
    try {
      return contracts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get active contract for tenant
  Contract? getActiveContractForTenant(String tenantId) {
    try {
      return contracts.firstWhere(
        (c) =>
            c.tenantId == tenantId &&
            (c.status == 'aktif' || c.status == 'akan_habis'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Filter options
  List<Map<String, String>> get filterOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'aktif', 'label': 'Aktif'},
    {'value': 'akan_habis', 'label': 'Akan Habis'},
    {'value': 'berakhir', 'label': 'Berakhir'},
  ];
}
