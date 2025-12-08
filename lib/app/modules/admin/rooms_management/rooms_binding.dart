// FILE: lib/app/modules/admin/rooms_management/rooms_binding.dart
import 'package:get/get.dart';
import 'rooms_controller.dart';

/// Binding for Rooms Management module
class RoomsBinding extends Bindings {
  @override
  void dependencies() {
    // SupabaseService is already registered in InitialBinding
    // Just inject RoomsController
    Get.lazyPut<RoomsController>(() => RoomsController());
  }
}
