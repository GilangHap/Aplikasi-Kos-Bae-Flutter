import 'package:get/get.dart';
import 'contracts_controller.dart';

/// Binding for Contracts module
class ContractsBinding extends Bindings {
  @override
  void dependencies() {
    // Use permanent to keep the same controller instance
    if (!Get.isRegistered<ContractsController>()) {
      Get.put<ContractsController>(ContractsController(), permanent: true);
    }
  }
}
