// FILE: lib/app/modules/tenant/announcements/tenant_announcements_binding.dart
import 'package:get/get.dart';
import 'tenant_announcements_controller.dart';

class TenantAnnouncementsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenantAnnouncementsController>(() => TenantAnnouncementsController());
  }
}
