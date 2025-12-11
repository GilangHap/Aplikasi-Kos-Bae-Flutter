import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

/// Dashboard Controller - Manages dashboard statistics and realtime updates
class DashboardController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Loading state
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // Statistics
  final totalRooms = 0.obs;
  final occupiedRooms = 0.obs;
  final availableRooms = 0.obs;
  final activeTenants = 0.obs;
  final totalTenants = 0.obs;
  
  // Bills statistics
  final pendingBills = 0.obs;
  final overdueBills = 0.obs;
  final paidBills = 0.obs;
  final totalBillsAmount = 0.0.obs;
  final paidAmount = 0.0.obs;
  final pendingAmount = 0.0.obs;
  
  // Revenue
  final monthlyRevenue = 0.0.obs;
  final totalRevenue = 0.0.obs;
  
  // Complaints
  final activeComplaints = 0.obs;
  final resolvedComplaints = 0.obs;

  // Realtime subscription
  RealtimeChannel? _dashboardChannel;

  // Computed properties
  double get occupancyRate => totalRooms.value > 0
      ? (occupiedRooms.value / totalRooms.value) * 100
      : 0.0;

  double get collectionRate => totalBillsAmount.value > 0
      ? (paidAmount.value / totalBillsAmount.value) * 100
      : 0.0;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    _dashboardChannel?.unsubscribe();
    super.onClose();
  }

  /// Fetch all dashboard statistics
  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Fetch all data in parallel
      await Future.wait([
        _fetchRoomStats(),
        _fetchTenantStats(),
        _fetchBillStats(),
        _fetchComplaintStats(),
      ]);

      print('✅ Dashboard data loaded successfully');
    } catch (e) {
      errorMessage.value = 'Gagal memuat data dashboard: $e';
      print('❌ Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch room statistics
  Future<void> _fetchRoomStats() async {
    try {
      final rooms = await _supabaseService.fetchRooms();
      
      totalRooms.value = rooms.length;
      occupiedRooms.value = rooms.where((r) => r.status == 'terisi').length;
      availableRooms.value = rooms.where((r) => r.status == 'kosong').length;

      print('📊 Rooms: ${totalRooms.value} total, ${occupiedRooms.value} occupied');
    } catch (e) {
      print('❌ Error fetching room stats: $e');
    }
  }

  /// Fetch tenant statistics
  Future<void> _fetchTenantStats() async {
    try {
      final allTenants = await _supabaseService.fetchTenants();
      final active = await _supabaseService.fetchTenants(status: 'aktif');
      
      totalTenants.value = allTenants.length;
      activeTenants.value = active.length;

      print('👥 Tenants: ${activeTenants.value} active of ${totalTenants.value} total');
    } catch (e) {
      print('❌ Error fetching tenant stats: $e');
    }
  }

  /// Fetch bill statistics
  Future<void> _fetchBillStats() async {
    try {
      // Fetch current month bills
      final now = DateTime.now();
      final bills = await _supabaseService.fetchBills(month: now);
      
      pendingBills.value = bills.where((b) => b.status == 'pending').length;
      overdueBills.value = bills.where((b) => b.status == 'overdue').length;
      paidBills.value = bills.where((b) => b.status == 'paid').length;
      
      totalBillsAmount.value = bills.fold(0.0, (sum, b) => sum + b.amount);
      paidAmount.value = bills
          .where((b) => b.status == 'paid')
          .fold(0.0, (sum, b) => sum + b.amount);
      pendingAmount.value = bills
          .where((b) => b.status != 'paid')
          .fold(0.0, (sum, b) => sum + b.remainingAmount);
      
      monthlyRevenue.value = paidAmount.value;
      
      // Calculate total revenue from all paid bills
      final allPaidBills = await _supabaseService.fetchBills(status: 'paid');
      totalRevenue.value = allPaidBills.fold(0.0, (sum, b) => sum + b.amount);

      print('💰 Bills: ${pendingBills.value} pending, ${paidBills.value} paid');
      print('💵 Revenue: Rp ${monthlyRevenue.value} this month');
    } catch (e) {
      print('❌ Error fetching bill stats: $e');
    }
  }

  /// Fetch complaint statistics
  Future<void> _fetchComplaintStats() async {
    try {
      final response = await _supabaseService.client
          .from('complaints')
          .select('status');
      
      final complaints = response as List;
      activeComplaints.value = complaints.where((c) => c['status'] == 'open' || c['status'] == 'in_progress').length;
      resolvedComplaints.value = complaints.where((c) => c['status'] == 'resolved').length;

      print('⚠️ Complaints: ${activeComplaints.value} active');
    } catch (e) {
      print('❌ Error fetching complaint stats: $e');
      // Set to 0 if table doesn't exist yet
      activeComplaints.value = 0;
      resolvedComplaints.value = 0;
    }
  }

  /// Setup realtime subscription for live updates
  void _setupRealtimeSubscription() {
    _dashboardChannel = _supabaseService.client
        .channel('dashboard_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          callback: (payload) {
            print('🔄 Rooms updated, refreshing dashboard...');
            fetchDashboardData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tenants',
          callback: (payload) {
            print('🔄 Tenants updated, refreshing dashboard...');
            fetchDashboardData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bills',
          callback: (payload) {
            print('🔄 Bills updated, refreshing dashboard...');
            fetchDashboardData();
          },
        )
        .subscribe();

    print('📡 Realtime subscription active for dashboard');
  }

  /// Refresh dashboard data
  Future<void> refreshData() async {
    await fetchDashboardData();
  }
}
