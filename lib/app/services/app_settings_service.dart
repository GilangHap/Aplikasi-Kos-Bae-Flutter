// FILE: lib/app/services/app_settings_service.dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger/app_logger.dart';

/// Global service to manage application settings
/// Settings are loaded once and cached for performance
class AppSettingsService extends GetxService {
  static AppSettingsService get to => Get.find<AppSettingsService>();
  
  // Settings values with defaults
  final dueDateDay = 10.obs;
  final lateFeePercentage = 5.obs;
  final gracePeriodDays = 3.obs;
  final enableLateFee = true.obs;
  final enableReminders = true.obs;
  final reminderDaysBefore = 3.obs;
  
  final isLoaded = false.obs;
  
  /// Initialize and load settings
  Future<AppSettingsService> init() async {
    await loadSettings();
    return this;
  }
  
  /// Load settings from database
  Future<void> loadSettings() async {
    try {
      final client = Supabase.instance.client;
      
      final response = await client
          .from('app_settings')
          .select()
          .eq('id', 'default')
          .maybeSingle();
      
      if (response != null) {
        dueDateDay.value = response['due_date_day'] ?? 10;
        lateFeePercentage.value = response['late_fee_percentage'] ?? 5;
        gracePeriodDays.value = response['grace_period_days'] ?? 3;
        enableLateFee.value = response['enable_late_fee'] ?? true;
        enableReminders.value = response['enable_reminders'] ?? true;
        reminderDaysBefore.value = response['reminder_days_before'] ?? 3;
        
        AppLogger.success('App settings loaded from database', tag: 'AppSettings');
      } else {
        AppLogger.debug('Using default app settings', tag: 'AppSettings');
      }
      
      isLoaded.value = true;
    } catch (e) {
      AppLogger.error('Error loading app settings, using defaults', error: e, tag: 'AppSettings');
      isLoaded.value = true; // Use default values
    }
  }
  
  /// Reload settings (call after saving)
  Future<void> reload() async {
    await loadSettings();
  }
  
  /// Calculate due date for a given month/year
  DateTime calculateDueDate(int year, int month) {
    // Ensure day is valid for the month
    int day = dueDateDay.value;
    int lastDayOfMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfMonth) {
      day = lastDayOfMonth;
    }
    return DateTime(year, month, day);
  }
  
  /// Calculate due date for next billing cycle
  DateTime getNextDueDate() {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    
    // If current day is past due date, move to next month
    if (now.day > dueDateDay.value) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    
    return calculateDueDate(year, month);
  }
  
  /// Check if a date is within reminder period
  bool isWithinReminderPeriod(DateTime dueDate) {
    if (!enableReminders.value) return false;
    
    final now = DateTime.now();
    final reminderDate = dueDate.subtract(Duration(days: reminderDaysBefore.value));
    
    return now.isAfter(reminderDate) && now.isBefore(dueDate);
  }
  
  /// Calculate late fee for an amount
  double calculateLateFee(double amount, DateTime dueDate) {
    if (!enableLateFee.value) return 0;
    
    final now = DateTime.now();
    final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays.value));
    
    // Only apply late fee after grace period
    if (now.isAfter(gracePeriodEnd)) {
      return amount * (lateFeePercentage.value / 100);
    }
    
    return 0;
  }
  
  /// Check if bill is overdue (past due date + grace period)
  bool isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays.value));
    return now.isAfter(gracePeriodEnd);
  }
  
  /// Check if bill is in grace period
  bool isInGracePeriod(DateTime dueDate) {
    final now = DateTime.now();
    final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays.value));
    return now.isAfter(dueDate) && now.isBefore(gracePeriodEnd);
  }
}
