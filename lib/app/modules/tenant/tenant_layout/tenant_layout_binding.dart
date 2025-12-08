// FILE: lib/app/modules/tenant/tenant_layout/tenant_layout_binding.dart
import 'package:get/get.dart';
import 'tenant_layout_controller.dart';
import '../tenant_nav/tenant_nav_controller.dart';
import '../home/home_controller.dart';
import '../complaints/tenant_complaints_controller.dart';
import '../bills/tenant_bills_controller.dart';
import '../profile/tenant_profile_controller.dart';

/// Binding for tenant layout
class TenantLayoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenantLayoutController>(() => TenantLayoutController());
    Get.lazyPut<TenantNavController>(() => TenantNavController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<TenantComplaintsController>(() => TenantComplaintsController());
    Get.lazyPut<TenantBillsController>(() => TenantBillsController());
    Get.lazyPut<TenantProfileController>(() => TenantProfileController());
  }
}
