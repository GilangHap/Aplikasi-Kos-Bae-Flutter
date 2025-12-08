// FILE: lib/app/modules/admin/rooms_management/room_form_binding.dart
import 'package:get/get.dart';
import 'room_form_controller.dart';

/// Binding for Room Form
class RoomFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoomFormController>(() => RoomFormController());
  }
}
