// FILE: lib/app/routes/app_routes.dart
/// Route name constants for Kos Bae application
///
/// Admin routes start with /admin
/// Tenant routes start with /tenant
abstract class AppRoutes {
  AppRoutes._();

  // Initial and auth routes
  static const INITIAL = '/';
  static const SPLASH = '/splash';
  static const LOGIN = '/login';

  // Admin routes
  static const ADMIN_LAYOUT = '/admin';
  static const ADMIN_DASHBOARD = '/admin/dashboard';
  static const ADMIN_ROOMS = '/admin/rooms';
  static const ADMIN_ROOM_ADD = '/admin/rooms/add';
  static const ADMIN_ROOM_EDIT = '/admin/rooms/edit';
  static const ADMIN_ROOM_DETAIL = '/admin/rooms/detail';
  static const ADMIN_TENANTS = '/admin/tenants';
  static const ADMIN_TENANT_DETAIL = '/admin/tenants/detail';
  static const ADMIN_TENANT_FORM = '/admin/tenants/form';
  static const ADMIN_BILLS = '/admin/bills';
  static const ADMIN_BILL_DETAIL = '/admin/bills/detail';
  static const ADMIN_BILL_FORM = '/admin/bills/form';
  static const ADMIN_BILLING = '/admin/billing';
  static const ADMIN_PAYMENTS = '/admin/payments';
  static const ADMIN_PAYMENT_DETAIL = '/admin/payments/detail';
  static const ADMIN_COMPLAINTS = '/admin/complaints';
  static const ADMIN_COMPLAINT_DETAIL = '/admin/complaints/detail';
  static const ADMIN_ANNOUNCEMENTS = '/admin/announcements';
  static const ADMIN_ANNOUNCEMENT_DETAIL = '/admin/announcements/detail';
  static const ADMIN_ANNOUNCEMENT_FORM = '/admin/announcements/form';
  static const ADMIN_CONTRACTS = '/admin/contracts';
  static const ADMIN_CONTRACT_DETAIL = '/admin/contracts/detail';
  static const ADMIN_CONTRACT_FORM = '/admin/contracts/form';
  static const ADMIN_SETTINGS = '/admin/settings';

  // Tenant routes
  static const TENANT_LAYOUT = '/tenant';
  static const TENANT_HOME = '/tenant/home';
  static const TENANT_BILLS = '/tenant/bills';
  static const TENANT_COMPLAINTS = '/tenant/complaints';
  static const TENANT_PROFILE = '/tenant/profile';
}
