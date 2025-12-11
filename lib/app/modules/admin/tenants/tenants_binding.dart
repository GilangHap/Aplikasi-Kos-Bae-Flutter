import 'package:get/get.dart';
import 'tenants_controller.dart';

/// Binding for Tenants Management
class TenantsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenantsController>(() => TenantsController());
  }
}
