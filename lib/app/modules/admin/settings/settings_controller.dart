// FILE: lib/app/modules/admin/settings/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/app_settings_service.dart';
import '../../../core/logger/app_logger.dart';

/// Controller for Admin Settings
class SettingsController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  final _authService = Get.find<AuthService>();
  
  // Loading states
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  
  // Settings values
  final dueDateDay = 10.obs; // Default: tanggal 10 setiap bulan
  final lateFeePercentage = 5.obs; // Default: 5%
  final gracePeriodDays = 3.obs; // Default: 3 hari
  final enableLateFee = true.obs;
  final enableReminders = true.obs;
  final reminderDaysBefore = 3.obs;
  
  // Text controllers
  late TextEditingController dueDateController;
  late TextEditingController lateFeeController;
  late TextEditingController gracePeriodController;
  late TextEditingController reminderDaysController;
  
  @override
  void onInit() {
    super.onInit();
    dueDateController = TextEditingController(text: dueDateDay.value.toString());
    lateFeeController = TextEditingController(text: lateFeePercentage.value.toString());
    gracePeriodController = TextEditingController(text: gracePeriodDays.value.toString());
    reminderDaysController = TextEditingController(text: reminderDaysBefore.value.toString());
    loadSettings();
  }
  
  @override
  void onClose() {
    dueDateController.dispose();
    lateFeeController.dispose();
    gracePeriodController.dispose();
    reminderDaysController.dispose();
    super.onClose();
  }
  
  /// Load settings from database
  Future<void> loadSettings() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _supabaseService.client
          .from('app_settings')
          .select()
          .maybeSingle();
      
      if (response != null) {
        dueDateDay.value = response['due_date_day'] ?? 10;
        lateFeePercentage.value = response['late_fee_percentage'] ?? 5;
        gracePeriodDays.value = response['grace_period_days'] ?? 3;
        enableLateFee.value = response['enable_late_fee'] ?? true;
        enableReminders.value = response['enable_reminders'] ?? true;
        reminderDaysBefore.value = response['reminder_days_before'] ?? 3;
        
        // Update text controllers
        dueDateController.text = dueDateDay.value.toString();
        lateFeeController.text = lateFeePercentage.value.toString();
        gracePeriodController.text = gracePeriodDays.value.toString();
        reminderDaysController.text = reminderDaysBefore.value.toString();
      }
      
      AppLogger.success('Settings loaded', tag: 'Settings');
    } catch (e) {
      AppLogger.error('Error loading settings', error: e, tag: 'Settings');
      // Use default values if settings table doesn't exist
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Save settings to database
  Future<bool> saveSettings() async {
    try {
      isSaving.value = true;
      errorMessage.value = '';
      
      // Validate inputs
      final dueDate = int.tryParse(dueDateController.text) ?? 10;
      final lateFee = int.tryParse(lateFeeController.text) ?? 5;
      final gracePeriod = int.tryParse(gracePeriodController.text) ?? 3;
      final reminderDays = int.tryParse(reminderDaysController.text) ?? 3;
      
      if (dueDate < 1 || dueDate > 28) {
        Get.snackbar(
          'Error',
          'Tanggal jatuh tempo harus antara 1-28',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
      
      // Update observables
      dueDateDay.value = dueDate;
      lateFeePercentage.value = lateFee;
      gracePeriodDays.value = gracePeriod;
      reminderDaysBefore.value = reminderDays;
      
      // Upsert settings
      await _supabaseService.client.from('app_settings').upsert({
        'id': 'default',
        'due_date_day': dueDate,
        'late_fee_percentage': lateFee,
        'grace_period_days': gracePeriod,
        'enable_late_fee': enableLateFee.value,
        'enable_reminders': enableReminders.value,
        'reminder_days_before': reminderDays,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Reload global app settings service
      if (Get.isRegistered<AppSettingsService>()) {
        await Get.find<AppSettingsService>().reload();
      }
      
      Get.snackbar(
        'Berhasil',
        'Pengaturan berhasil disimpan',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      
      AppLogger.success('Settings saved', tag: 'Settings');
      return true;
    } catch (e) {
      AppLogger.error('Error saving settings', error: e, tag: 'Settings');
      Get.snackbar(
        'Error',
        'Gagal menyimpan pengaturan',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    await _authService.signOut();
  }
}
