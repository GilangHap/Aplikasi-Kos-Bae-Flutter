import 'package:get/get.dart';
import '../../../models/tenant_model.dart';
import '../../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../help/tenant_help_view.dart';

class HomeController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _supabaseService = Get.find<SupabaseService>();

  final tenant = Rxn<Tenant>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  final unpaidBillsCount = 0.obs;
  final activeComplaintsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadTenantData();
  }

  Future<void> loadTenantData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId == null) {
        errorMessage.value = 'Data penghuni tidak ditemukan';
        return;
      }

      final tenantData = await _supabaseService.getTenantById(tenantId);
      if (tenantData == null) {
        errorMessage.value = 'Data penghuni tidak ditemukan';
        return;
      }

      tenant.value = tenantData;

      // Fetch additional stats
      await _fetchStats(tenantId);
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
      print('❌ Error loading tenant home data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchStats(String tenantId) async {
    try {
      // Count unpaid bills
      final billsResponse = await _supabaseService.client
          .from('bills')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('status', 'pending')
          .count(CountOption.exact);
      
      unpaidBillsCount.value = billsResponse.count;

      // Count active complaints
      final complaintsResponse = await _supabaseService.client
          .from('complaints')
          .select('id')
          .eq('tenant_id', tenantId)
          .neq('status', 'selesai')
          .count(CountOption.exact);
          
      activeComplaintsCount.value = complaintsResponse.count;
    } catch (e) {
      print('⚠️ Error fetching dashboard stats: $e');
    }
  }

  Future<void> refreshData() async {
    await loadTenantData();
  }

  // Status helpers
  bool get isActive => tenant.value?.status == 'aktif';
  bool get isInactive => tenant.value?.status == 'nonaktif';
  bool get hasLeft => tenant.value?.status == 'keluar';

  void showHelpPage() {
    Get.to(() => const TenantHelpView());
  }
}
