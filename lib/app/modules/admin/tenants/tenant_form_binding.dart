import 'package:get/get.dart';
import 'tenant_form_controller.dart';

/// Binding for Tenant Form (Add/Edit)
class TenantFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenantFormController>(() => TenantFormController());
  }
}
