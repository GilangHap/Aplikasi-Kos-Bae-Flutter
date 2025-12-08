// FILE: lib/app/modules/admin/payments/payments_binding.dart
import 'package:get/get.dart';
import 'payments_controller.dart';

/// Binding for Payments module
class PaymentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentsController>(() => PaymentsController());
  }
}
