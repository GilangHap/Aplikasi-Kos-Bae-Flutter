// FILE: lib/app/modules/admin/bills/bill_form_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/bill_model.dart';
import '../../../models/tenant_model.dart';
import '../../../models/room_model.dart';
import '../../../services/supabase_service.dart';
import '../../../services/app_settings_service.dart';

/// Controller for Bill Form (Add/Edit)
class BillFormController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // Form Key
  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final adminNotesController = TextEditingController();

  // Observables
  final isLoading = false.obs;
  final isEditMode = false.obs;
  final selectedTenantId = Rxn<String>();
  final selectedRoomId = Rxn<String>();
  final selectedType = 'sewa'.obs;
  final selectedStatus = 'pending'.obs;
  final dueDate = DateTime.now().add(const Duration(days: 10)).obs;
  final billingPeriodStart = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  ).obs;
  final billingPeriodEnd = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  ).obs;

  // Data
  final tenants = <Tenant>[].obs;
  final rooms = <Room>[].obs;
  Bill? existingBill;

  @override
  void onInit() {
    super.onInit();
    _loadData();
    _initDueDateFromSettings();

    // Check if editing
    if (Get.arguments != null && Get.arguments is Bill) {
      existingBill = Get.arguments as Bill;
      isEditMode.value = true;
      _populateForm();
    }
  }
  
  /// Initialize due date from app settings
  void _initDueDateFromSettings() {
    if (Get.isRegistered<AppSettingsService>()) {
      final settings = Get.find<AppSettingsService>();
      dueDate.value = settings.getNextDueDate();
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    notesController.dispose();
    adminNotesController.dispose();
    super.onClose();
  }

  Future<void> _loadData() async {
    try {
      isLoading.value = true;

      // Load active tenants
      final tenantList = await _supabaseService.fetchTenants(status: 'aktif');
      tenants.value = tenantList;

      // Load rooms
      final roomList = await _supabaseService.fetchRooms();
      rooms.value = roomList;
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _populateForm() {
    if (existingBill == null) return;

    amountController.text = existingBill!.amount.toStringAsFixed(0);
    notesController.text = existingBill!.notes ?? '';
    adminNotesController.text = existingBill!.adminNotes ?? '';
    selectedTenantId.value = existingBill!.tenantId;
    selectedRoomId.value = existingBill!.roomId;
    selectedType.value = existingBill!.type;
    selectedStatus.value = existingBill!.status;
    dueDate.value = existingBill!.dueDate;
    billingPeriodStart.value = existingBill!.billingPeriodStart;
    billingPeriodEnd.value = existingBill!.billingPeriodEnd;
  }

  /// When tenant is selected, auto-fill room
  void onTenantSelected(String? tenantId) async {
    selectedTenantId.value = tenantId;
    if (tenantId != null) {
      final tenant = tenants.firstWhereOrNull((t) => t.id == tenantId);
      
      // Get room from tenant's contract instead of direct roomId access
      if (tenant?.contractId != null) {
        try {
          final contract = await _supabaseService.client
              .from('contracts')
              .select('room_id')
              .eq('id', tenant!.contractId!)
              .single();
          
          if (contract['room_id'] != null) {
            selectedRoomId.value = contract['room_id'];

            // If type is 'sewa', auto-fill with room price
            if (selectedType.value == 'sewa') {
              final room = rooms.firstWhereOrNull((r) => r.id == contract['room_id']);
              if (room != null) {
                amountController.text = room.price.toStringAsFixed(0);
              }
            }
          }
        } catch (e) {
          print('Error fetching contract for room: $e');
        }
      }
    }
  }

  /// When type changes, adjust amount if needed
  void onTypeChanged(String type) {
    selectedType.value = type;

    // If type is sewa and room is selected, auto-fill price
    if (type == 'sewa' && selectedRoomId.value != null) {
      final room = rooms.firstWhereOrNull((r) => r.id == selectedRoomId.value);
      if (room != null) {
        amountController.text = room.price.toStringAsFixed(0);
      }
    }
  }

  Future<void> selectDueDate() async {
    final selected = await showDatePicker(
      context: Get.context!,
      initialDate: dueDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      dueDate.value = selected;
    }
  }

  Future<void> selectBillingPeriod() async {
    final selected = await showDatePicker(
      context: Get.context!,
      initialDate: billingPeriodStart.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected != null) {
      billingPeriodStart.value = DateTime(selected.year, selected.month, 1);
      billingPeriodEnd.value = DateTime(selected.year, selected.month + 1, 0);
    }
  }

  Future<void> saveBill() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedTenantId.value == null) {
      Get.snackbar('Error', 'Pilih penghuni terlebih dahulu');
      return;
    }

    try {
      isLoading.value = true;

      final amount = double.tryParse(amountController.text) ?? 0;

      final bill = Bill(
        id: existingBill?.id ?? '',
        tenantId: selectedTenantId.value!,
        roomId: selectedRoomId.value,
        amount: amount,
        type: selectedType.value,
        status: selectedStatus.value,
        dueDate: dueDate.value,
        billingPeriodStart: billingPeriodStart.value,
        billingPeriodEnd: billingPeriodEnd.value,
        notes: notesController.text.isNotEmpty ? notesController.text : null,
        adminNotes: adminNotesController.text.isNotEmpty
            ? adminNotesController.text
            : null,
        createdAt: existingBill?.createdAt ?? DateTime.now(),
      );

      if (isEditMode.value) {
        await _supabaseService.updateBill(bill);
        Get.snackbar(
          'Sukses',
          'Tagihan berhasil diupdate',
          backgroundColor: const Color(0xFFB9F3CC),
          colorText: const Color(0xFF2D3748),
        );
      } else {
        await _supabaseService.createBill(bill);
        Get.snackbar(
          'Sukses',
          'Tagihan berhasil ditambahkan',
          backgroundColor: const Color(0xFFB9F3CC),
          colorText: const Color(0xFF2D3748),
        );
      }

      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menyimpan tagihan: $e',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: const Color(0xFF2D3748),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Type options
  List<Map<String, dynamic>> get typeOptions => [
    {'value': 'sewa', 'label': 'Sewa Kamar', 'icon': Icons.home},
    {'value': 'listrik', 'label': 'Listrik', 'icon': Icons.bolt},
    {'value': 'air', 'label': 'Air', 'icon': Icons.water_drop},
    {'value': 'deposit', 'label': 'Deposit', 'icon': Icons.savings},
    {'value': 'denda', 'label': 'Denda', 'icon': Icons.gavel},
    {'value': 'lainnya', 'label': 'Lainnya', 'icon': Icons.receipt},
  ];

  // Status options
  List<Map<String, dynamic>> get statusOptions => [
    {'value': 'pending', 'label': 'Menunggu', 'color': const Color(0xFFFFD6A5)},
    {
      'value': 'verified',
      'label': 'Terverifikasi',
      'color': const Color(0xFFA9C9FF),
    },
    {'value': 'paid', 'label': 'Lunas', 'color': const Color(0xFFB9F3CC)},
    {
      'value': 'overdue',
      'label': 'Terlambat',
      'color': const Color(0xFFF7C4D4),
    },
  ];
}
