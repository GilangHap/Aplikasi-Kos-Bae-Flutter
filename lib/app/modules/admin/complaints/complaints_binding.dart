import 'package:get/get.dart';
import 'complaints_controller.dart';

/// Binding for Complaints module
class ComplaintsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ComplaintsController>(() => ComplaintsController());
  }
}
