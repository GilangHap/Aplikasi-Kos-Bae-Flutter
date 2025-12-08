import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/tenant_model.dart';
import '../../../routes/app_routes.dart';

class TenantProfileController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  final _authService = Get.find<AuthService>();

  final tenant = Rxn<Tenant>();
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId != null) {
        final tenantData = await _supabaseService.getTenantById(tenantId);
        if (tenantData != null) {
          tenant.value = tenantData;
        }
      }
    } catch (e) {
      print('❌ Error fetching profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}
