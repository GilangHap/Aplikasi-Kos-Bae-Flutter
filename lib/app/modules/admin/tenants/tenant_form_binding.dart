// FILE: lib/app/modules/admin/tenants/tenant_form_binding.dart
import 'package:get/get.dart';
import 'tenant_form_controller.dart';

/// Binding for Tenant Form (Add/Edit)
class TenantFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenantFormController>(() => TenantFormController());
  }
}
