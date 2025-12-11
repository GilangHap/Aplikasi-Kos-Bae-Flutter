import 'package:get/get.dart';
import 'edit_profile_controller.dart';

/// Binding for Edit Profile page
class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}
