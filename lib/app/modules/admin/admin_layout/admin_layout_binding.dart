import 'package:get/get.dart';
import 'admin_layout_controller.dart';
import '../dashboard/dashboard_controller.dart';
import '../admin_drawer/admin_drawer_controller.dart';
import '../rooms_management/rooms_controller.dart';
import '../tenants/tenants_controller.dart';
import '../bills/bills_controller.dart';
import '../payments/payments_controller.dart';
import '../complaints/complaints_controller.dart';

/// Binding for admin layout
/// Initializes controllers needed for admin interface
class AdminLayoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminLayoutController>(() => AdminLayoutController());
    Get.lazyPut<AdminDrawerController>(() => AdminDrawerController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<RoomsController>(() => RoomsController());
    Get.lazyPut<TenantsController>(() => TenantsController());
    Get.lazyPut<BillsController>(() => BillsController());
    Get.lazyPut<PaymentsController>(() => PaymentsController());
    Get.lazyPut<ComplaintsController>(() => ComplaintsController());
  }
}
