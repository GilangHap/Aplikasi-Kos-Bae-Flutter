// FILE: lib/app/modules/admin/bills/bills_binding.dart
import 'package:get/get.dart';
import 'bills_controller.dart';
import 'bill_form_controller.dart';

/// Binding for Bills module
class BillsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillsController>(() => BillsController());
  }
}

/// Binding for Bill Form
class BillFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillFormController>(() => BillFormController());
  }
}
