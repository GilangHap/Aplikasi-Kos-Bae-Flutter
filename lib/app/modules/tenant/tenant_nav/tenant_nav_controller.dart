// FILE: lib/app/modules/tenant/tenant_nav/tenant_nav_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_view.dart';
import '../bills/bills_view.dart';
import '../complaints/tenant_complaints_view.dart';
import '../profile/profile_view.dart';

/// Controller for tenant bottom navigation
class TenantNavController extends GetxController {
  final RxInt currentIndex = 0.obs;
  
  // Pages for bottom navigation
  final List<Widget> pages = const [
    TenantHomeView(),
    TenantBillsView(),
    TenantComplaintsView(),
    TenantProfileView(),
  ];
  
  /// Change bottom nav index
  void changeIndex(int index) {
    currentIndex.value = index;
  }
}
