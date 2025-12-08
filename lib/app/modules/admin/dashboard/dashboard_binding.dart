// FILE: lib/app/modules/admin/dashboard/dashboard_binding.dart
import 'package:get/get.dart';
import 'dashboard_controller.dart';

/// Dashboard Binding
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
