import 'package:get/get.dart';
import 'announcements_controller.dart';

class AnnouncementsBinding extends Bindings {
  @override
  void dependencies() {
    // Use permanent to keep the same controller instance
    // Check if already registered to avoid duplicates
    if (!Get.isRegistered<AnnouncementsController>()) {
      Get.put<AnnouncementsController>(
        AnnouncementsController(),
        permanent: true,
      );
    }
  }
}
