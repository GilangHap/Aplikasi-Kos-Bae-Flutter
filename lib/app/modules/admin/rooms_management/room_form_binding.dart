import 'package:get/get.dart';
import 'room_form_controller.dart';

/// Binding for Room Form
class RoomFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoomFormController>(() => RoomFormController());
  }
}
