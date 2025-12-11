import 'package:get/get.dart';
import '../../../models/tenant_model.dart';
import '../../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../../../services/app_settings_service.dart';
import '../help/tenant_help_view.dart';

class HomeController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _supabaseService = Get.find<SupabaseService>();

  final tenant = Rxn<Tenant>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  final unpaidBillsCount = 0.obs;
  final overdueBillsCount = 0.obs;
  final reminderBillsCount = 0.obs;
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

      final userId = _authService.currentUser.value?.id;
      print('🔍 Loading tenant data for user: $userId');

      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId == null) {
        print('❌ No tenant record found for user_id: $userId');
        errorMessage.value = 'Akun Anda belum terhubung dengan data penghuni. Silakan hubungi admin untuk menghubungkan akun Anda.';
        return;
      }

      print('✅ Found tenant ID: $tenantId');
      final tenantData = await _supabaseService.getTenantById(tenantId);
      if (tenantData == null) {
        print('❌ Tenant data not found for ID: $tenantId');
        errorMessage.value = 'Data penghuni tidak ditemukan di database.';
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
      // Get settings for grace period and reminder calculation
      int gracePeriodDays = 3;
      int reminderDaysBefore = 3;
      
      if (Get.isRegistered<AppSettingsService>()) {
        final settings = Get.find<AppSettingsService>();
        gracePeriodDays = settings.gracePeriodDays.value;
        reminderDaysBefore = settings.reminderDaysBefore.value;
      }
      
      final now = DateTime.now();
      
      // Fetch all unpaid bills
      final billsResponse = await _supabaseService.client
          .from('bills')
          .select('id, due_date, status')
          .eq('tenant_id', tenantId)
          .neq('status', 'paid');
      
      int unpaid = 0;
      int overdue = 0;
      int needsReminder = 0;
      
      for (final bill in billsResponse as List) {
        final dueDate = DateTime.parse(bill['due_date']);
        final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays));
        final reminderDate = dueDate.subtract(Duration(days: reminderDaysBefore));
        
        unpaid++;
        
        if (now.isAfter(gracePeriodEnd)) {
          overdue++;
        } else if (now.isAfter(reminderDate) && now.isBefore(dueDate)) {
          needsReminder++;
        }
      }
      
      unpaidBillsCount.value = unpaid;
      overdueBillsCount.value = overdue;
      reminderBillsCount.value = needsReminder;

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
