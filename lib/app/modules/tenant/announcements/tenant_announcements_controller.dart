import 'package:get/get.dart';
import '../../../models/announcement_model.dart';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/logger/app_logger.dart';

/// Controller for Tenant Announcements
class TenantAnnouncementsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  final _authService = Get.find<AuthService>();

  final announcements = <Announcement>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _supabaseService.fetchAnnouncements();
      announcements.value = result.map((json) => Announcement.fromJson(json)).toList();
      
      AppLogger.success('Fetched ${result.length} announcements', tag: 'TenantAnnouncements');
    } catch (e) {
      errorMessage.value = 'Gagal memuat pengumuman';
      AppLogger.error('Error fetching announcements', error: e, tag: 'TenantAnnouncements');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String announcementId) async {
    try {
      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId == null) return;
      
      await _supabaseService.client.from('announcement_reads').upsert({
        'announcement_id': announcementId,
        'tenant_id': tenantId,
        'read_at': DateTime.now().toIso8601String(),
      });
      
      AppLogger.debug('Marked announcement $announcementId as read', tag: 'TenantAnnouncements');
    } catch (e) {
      AppLogger.error('Error marking announcement as read', error: e, tag: 'TenantAnnouncements');
    }
  }

  Future<void> refreshData() async {
    await fetchAnnouncements();
  }
}
