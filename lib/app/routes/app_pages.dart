// FILE: lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import '../middlewares/role_middleware.dart';
import '../modules/admin/admin_layout/admin_layout_view.dart';
import '../modules/admin/admin_layout/admin_layout_binding.dart';
import '../modules/admin/rooms_management/rooms_view.dart';
import '../modules/admin/rooms_management/rooms_binding.dart';
import '../modules/admin/rooms_management/room_detail_view.dart';
import '../modules/admin/rooms_management/room_form_view.dart';
import '../modules/admin/rooms_management/room_form_binding.dart';
import '../modules/admin/tenants/tenants_view.dart';
import '../modules/admin/tenants/tenants_binding.dart';
import '../modules/admin/tenants/tenant_detail_view.dart';
import '../modules/admin/tenants/tenant_form_view.dart';
import '../modules/admin/tenants/tenant_form_binding.dart';
import '../modules/admin/bills/bills_view.dart';
import '../modules/admin/bills/bills_binding.dart';
import '../modules/admin/bills/bill_detail_view.dart';
import '../modules/admin/bills/bill_form_view.dart';
import '../modules/admin/payments/payments_view.dart';
import '../modules/admin/payments/payments_binding.dart';
import '../modules/admin/payments/payment_detail_view.dart';
import '../modules/admin/complaints/complaints_view.dart';
import '../modules/admin/complaints/complaints_binding.dart';
import '../modules/admin/complaints/complaint_detail_view.dart';
import '../modules/admin/announcements/announcements_view.dart';
import '../modules/admin/announcements/announcements_binding.dart';
import '../modules/admin/announcements/announcement_detail_view.dart';
import '../modules/admin/announcements/announcement_form_view.dart';
import '../modules/admin/contracts/contracts_view.dart';
import '../modules/admin/contracts/contracts_binding.dart';
import '../modules/admin/contracts/contract_detail_view.dart';
import '../modules/admin/contracts/contract_form_view.dart';
import '../modules/tenant/tenant_layout/tenant_layout_view.dart';
import '../modules/tenant/tenant_layout/tenant_layout_binding.dart';
import '../modules/auth/login/login_view.dart';
import '../modules/initial/initial_view.dart';
import 'app_routes.dart';

/// GetX pages configuration
/// Maps route names to page views with bindings and middlewares
class AppPages {
  AppPages._();

  static final routes = [
    // Initial route - determines user role and redirects
    GetPage(name: AppRoutes.INITIAL, page: () => const InitialView()),

    // Login
    GetPage(name: AppRoutes.LOGIN, page: () => const LoginView()),

    // Admin layout with drawer navigation
    // All admin pages are accessed via IndexedStack inside AdminLayoutView
    GetPage(
      name: AppRoutes.ADMIN_LAYOUT,
      page: () => const AdminLayoutView(),
      binding: AdminLayoutBinding(),
    ),

    // Rooms Management
    GetPage(
      name: AppRoutes.ADMIN_ROOMS,
      page: () => const RoomsView(),
      binding: RoomsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_ROOM_DETAIL,
      page: () => const RoomDetailView(),
    ),
    // Add Room Form
    GetPage(
      name: AppRoutes.ADMIN_ROOM_ADD,
      page: () => const RoomFormView(),
      binding: RoomFormBinding(),
    ),
    // Edit Room Form
    GetPage(
      name: AppRoutes.ADMIN_ROOM_EDIT,
      page: () => const RoomFormView(),
      binding: RoomFormBinding(),
    ),

    // Tenants Management
    GetPage(
      name: AppRoutes.ADMIN_TENANTS,
      page: () => const TenantsView(),
      binding: TenantsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_TENANT_DETAIL,
      page: () => const TenantDetailView(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_TENANT_FORM,
      page: () => const TenantFormView(),
      binding: TenantFormBinding(),
    ),

    // Bills Management
    GetPage(
      name: AppRoutes.ADMIN_BILLS,
      page: () => const BillsView(),
      binding: BillsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_BILL_DETAIL,
      page: () => const BillDetailView(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_BILL_FORM,
      page: () => const BillFormView(),
      binding: BillFormBinding(),
    ),

    // Payments Management
    GetPage(
      name: AppRoutes.ADMIN_PAYMENTS,
      page: () => const AdminPaymentsView(),
      binding: PaymentsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_PAYMENT_DETAIL,
      page: () => const PaymentDetailView(),
    ),

    // Complaints Management
    GetPage(
      name: AppRoutes.ADMIN_COMPLAINTS,
      page: () => const AdminComplaintsView(),
      binding: ComplaintsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_COMPLAINT_DETAIL,
      page: () => const ComplaintDetailView(),
    ),

    // Announcements Management
    GetPage(
      name: AppRoutes.ADMIN_ANNOUNCEMENTS,
      page: () => const AdminAnnouncementsView(),
      binding: AnnouncementsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_ANNOUNCEMENT_DETAIL,
      page: () => const AnnouncementDetailView(),
      binding: AnnouncementsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_ANNOUNCEMENT_FORM,
      page: () => const AnnouncementFormView(),
      binding: AnnouncementsBinding(),
    ),

    // Contracts Management
    GetPage(
      name: AppRoutes.ADMIN_CONTRACTS,
      page: () => const AdminContractsView(),
      binding: ContractsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_CONTRACT_DETAIL,
      page: () => const ContractDetailView(),
      binding: ContractsBinding(),
    ),
    GetPage(
      name: AppRoutes.ADMIN_CONTRACT_FORM,
      page: () => const ContractFormView(),
      binding: ContractsBinding(),
    ),

    // Tenant layout with bottom navigation
    // All tenant pages are accessed via IndexedStack inside TenantLayoutView
    GetPage(
      name: AppRoutes.TENANT_LAYOUT,
      page: () => const TenantLayoutView(),
      binding: TenantLayoutBinding(),
    ),
  ];
}
