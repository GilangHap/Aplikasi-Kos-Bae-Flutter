import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/complaint_model.dart';
import '../../../models/tenant_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Complaints Management
class ComplaintsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Observables
  final complaints = <Complaint>[].obs;
  final filteredComplaints = <Complaint>[].obs;
  final tenants = <Tenant>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // Filters
  final selectedStatus = 'all'.obs;
  final selectedCategory = 'all'.obs;
  final selectedTenantId = ''.obs;
  final searchQuery = ''.obs;

  // Search controller
  final searchController = TextEditingController();

  // Realtime subscription
  RealtimeChannel? _complaintsChannel;

  // Statistics
  final statistics = <String, dynamic>{
    'total': 0,
    'submitted': 0,
    'inProgress': 0,
    'resolved': 0,
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchComplaints();
    fetchTenants();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    searchController.dispose();
    _complaintsChannel?.unsubscribe();
    super.onClose();
  }

  /// Setup realtime subscription
  void _setupRealtimeSubscription() {
    _complaintsChannel = _supabaseService.client
        .channel('public:complaints')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'complaints',
          callback: (payload) {
            print('🔄 Complaints changed: ${payload.eventType}');
            fetchComplaints();
          },
        )
        .subscribe();

    print('📡 Realtime subscription active for complaints');
  }

  /// Fetch all complaints
  Future<void> fetchComplaints() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('📥 Fetching complaints...');

      // Try simple query first (no joins) to debug
      dynamic response;
      try {
        // Simple query - just get complaints data
        response = await _supabaseService.client
            .from('complaints')
            .select('*')
            .order('created_at', ascending: false);

        print('📦 Simple query response: $response');
        print('📦 Count: ${(response as List).length}');

        // If we got data, now try to enrich with tenant/room info
        if ((response as List).isNotEmpty) {
          // Try with joins
          try {
            response = await _supabaseService.client
                .from('complaints')
                .select('''
                  *,
                  tenants:tenant_id(id, name, phone, photo_url),
                  rooms:room_id(id, room_number)
                ''')
                .order('created_at', ascending: false);
            print('📦 Join query succeeded');
          } catch (joinError) {
            print('⚠️ Join failed, using simple data: $joinError');
            // Keep using simple response
          }
        }
      } catch (simpleError) {
        print('❌ Simple query also failed: $simpleError');
        rethrow;
      }

      print('📦 Final response type: ${response.runtimeType}');
      print('📦 Final response data: $response');

      final result = (response as List).map((json) {
        print('📄 Parsing complaint: ${json['id']} - ${json['title']}');
        return Complaint.fromJson(json as Map<String, dynamic>);
      }).toList();

      print('✅ Parsed ${result.length} complaints');

      complaints.value = result;
      _applyFilters();
      _calculateStatistics();
    } catch (e, stackTrace) {
      errorMessage.value = 'Gagal memuat data keluhan: ${e.toString()}';
      print('❌ Error fetching complaints: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch tenants for filter dropdown
  Future<void> fetchTenants() async {
    try {
      final result = await _supabaseService.fetchTenants();
      tenants.value = result;
    } catch (e) {
      print('❌ Error fetching tenants: $e');
    }
  }

  /// Calculate statistics
  void _calculateStatistics() {
    final allComplaints = complaints.toList();

    int submitted = 0;
    int inProgress = 0;
    int resolved = 0;

    for (final complaint in allComplaints) {
      switch (complaint.status) {
        case 'submitted':
          submitted++;
          break;
        case 'in_progress':
          inProgress++;
          break;
        case 'resolved':
          resolved++;
          break;
      }
    }

    statistics.value = {
      'total': allComplaints.length,
      'submitted': submitted,
      'inProgress': inProgress,
      'resolved': resolved,
    };
  }

  /// Apply local filters
  void _applyFilters() {
    var result = complaints.toList();

    // Apply status filter
    if (selectedStatus.value != 'all') {
      result = result.where((c) => c.status == selectedStatus.value).toList();
    }

    // Apply category filter
    if (selectedCategory.value != 'all') {
      result = result
          .where((c) => c.category == selectedCategory.value)
          .toList();
    }

    // Apply tenant filter
    if (selectedTenantId.value.isNotEmpty) {
      result = result
          .where((c) => c.tenantId == selectedTenantId.value)
          .toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            (c.tenantName?.toLowerCase().contains(q) ?? false) ||
            (c.roomNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    filteredComplaints.value = result;
  }

  /// Set status filter
  void setStatusFilter(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  /// Set category filter
  void setCategoryFilter(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  /// Set tenant filter
  void setTenantFilter(String tenantId) {
    selectedTenantId.value = tenantId;
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
    selectedStatus.value = 'all';
    selectedCategory.value = 'all';
    selectedTenantId.value = '';
    clearSearch();
  }

  /// Refresh data
  Future<void> refreshData() async {
    await fetchComplaints();
  }

  /// Update complaint status
  Future<bool> updateStatus(
    Complaint complaint,
    String newStatus, {
    String? notes,
  }) async {
    try {
      final oldStatus = complaint.status;

      // Update complaint status
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == 'resolved') {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
        updateData['resolved_by'] = _supabaseService.auth.currentUser?.id;
        if (notes != null && notes.isNotEmpty) {
          updateData['resolution_notes'] = notes;
        }
      }

      await _supabaseService.client
          .from('complaints')
          .update(updateData)
          .eq('id', complaint.id);

      // Add status history
      await _supabaseService.client.from('complaint_status_history').insert({
        'complaint_id': complaint.id,
        'from_status': oldStatus,
        'to_status': newStatus,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': _supabaseService.auth.currentUser?.id,
      });

      await fetchComplaints();

      Get.snackbar(
        'Sukses',
        'Status keluhan berhasil diupdate',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal mengupdate status: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Update admin notes
  Future<bool> updateAdminNotes(Complaint complaint, String notes) async {
    try {
      await _supabaseService.client
          .from('complaints')
          .update({
            'admin_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', complaint.id);

      await fetchComplaints();

      Get.snackbar(
        'Sukses',
        'Catatan berhasil disimpan',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal menyimpan catatan: ${e.toString()}',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Get complaint by ID
  Complaint? getComplaintById(String id) {
    try {
      return complaints.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get pending count (submitted + in_progress)
  int get pendingCount =>
      (statistics['submitted'] ?? 0) + (statistics['inProgress'] ?? 0);

  /// Status filter options
  List<Map<String, String>> get statusOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'submitted', 'label': 'Diajukan'},
    {'value': 'in_progress', 'label': 'Diproses'},
    {'value': 'resolved', 'label': 'Selesai'},
  ];

  /// Category filter options
  List<Map<String, String>> get categoryOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'fasilitas', 'label': 'Fasilitas'},
    {'value': 'kebersihan', 'label': 'Kebersihan'},
    {'value': 'keamanan', 'label': 'Keamanan'},
    {'value': 'listrik', 'label': 'Listrik'},
    {'value': 'air', 'label': 'Air'},
    {'value': 'lainnya', 'label': 'Lainnya'},
  ];
}
