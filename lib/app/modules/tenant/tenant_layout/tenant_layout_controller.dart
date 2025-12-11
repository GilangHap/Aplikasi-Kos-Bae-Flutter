import 'package:get/get.dart';

/// Controller for tenant layout
class TenantLayoutController extends GetxController {
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initialize();
  }
  
  Future<void> _initialize() async {
    isLoading.value = true;
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    isLoading.value = false;
  }
}
