// FILE: lib/app/modules/admin/tenants/tenants_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/tenant_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Tenants Management
class TenantsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Observables
  final tenants = <Tenant>[].obs;
  final filteredTenants = <Tenant>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // Filters & Search
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;
  final sortBy = 'name'.obs;

  // Search controller
  final searchController = TextEditingController();

  // Realtime subscription
  RealtimeChannel? _tenantsChannel;

  // Statistics
  final statistics = <String, int>{'total': 0, 'active': 0, 'inactive': 0, 'left': 0}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTenants();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    searchController.dispose();
    _tenantsChannel?.unsubscribe();
    super.onClose();
  }

  /// Setup realtime subscription for auto-update
  void _setupRealtimeSubscription() {
    _tenantsChannel = _supabaseService.client
        .channel('public:tenants')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tenants',
          callback: (payload) {
            print(
              '🔄 Realtime update received for tenants: ${payload.eventType}',
            );
            fetchTenants();
          },
        )
        .subscribe();

    print('📡 Realtime subscription active for tenants');
  }

  /// Fetch all tenants from Supabase
  Future<void> fetchTenants() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _supabaseService.fetchTenants(
        status: selectedStatus.value == 'all' ? null : selectedStatus.value,
        sortBy: sortBy.value,
        searchQuery: searchQuery.value.isEmpty ? null : searchQuery.value,
      );

      tenants.value = result;
      _applyFilters();
      await _loadStatistics();
    } catch (e) {
      errorMessage.value = 'Gagal memuat data penghuni: ${e.toString()}';
      print('❌ Error fetching tenants: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load statistics
  Future<void> _loadStatistics() async {
    try {
      final stats = await _supabaseService.getTenantStatistics();
      statistics.value = stats;
    } catch (e) {
      print('❌ Error loading statistics: $e');
    }
  }

  /// Apply local filters
  void _applyFilters() {
    var result = tenants.toList();

    // Apply status filter
    if (selectedStatus.value != 'all') {
      result = result.where((t) => t.status == selectedStatus.value).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((t) {
        return t.name.toLowerCase().contains(query) ||
            t.phone.toLowerCase().contains(query) ||
            (t.nik?.toLowerCase().contains(query) ?? false) ||
            (t.roomNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply sorting
    result.sort((a, b) {
      switch (sortBy.value) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'created_at':
          return b.createdAt.compareTo(a.createdAt);
        default:
          return 0;
      }
    });

    filteredTenants.value = result;
  }

  /// Set status filter
  void setStatusFilter(String status) {
    selectedStatus.value = status;
    _applyFilters();
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
    await fetchTenants();
  }

  /// Delete tenant with confirmation
  Future<bool> deleteTenant(Tenant tenant) async {
    try {
      await _supabaseService.deleteTenant(tenant.id);
      tenants.removeWhere((t) => t.id == tenant.id);
      _applyFilters();
      await _loadStatistics();
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal menghapus penghuni: ${e.toString()}';
      return false;
    }
  }

  /// Get tenant by ID
  Tenant? getTenantById(String id) {
    try {
      return tenants.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Status filter options
  List<Map<String, String>> get statusOptions => [
    {'value': 'all', 'label': 'Semua'},
    {'value': 'aktif', 'label': 'Aktif'},
    {'value': 'nonaktif', 'label': 'Nonaktif'},
    {'value': 'keluar', 'label': 'Keluar'},
  ];

  /// Sort options
  List<Map<String, String>> get sortOptions => [
    {'value': 'name', 'label': 'Nama (A-Z)'},
    {'value': 'created_at', 'label': 'Terbaru'},
  ];
}
