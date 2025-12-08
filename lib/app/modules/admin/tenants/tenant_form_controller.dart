// FILE: lib/app/modules/admin/tenants/tenant_form_controller.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../models/tenant_model.dart';
import '../../../models/contract_model.dart';
import '../../../services/supabase_service.dart';

/// Controller for Add/Edit Tenant Form
class TenantFormController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();

  // ... (rest of the file until _createAuthUser)


  // Form key
  final formKey = GlobalKey<FormState>();

  // Text Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final nikController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final obscurePassword = true.obs;

  // Photo
  final selectedPhoto = Rxn<XFile>();
  final photoBytes = Rxn<Uint8List>();
  final existingPhotoUrl = Rxn<String>();
  final removeExistingPhoto = false.obs;

  // Contract selection
  final availableContracts = <Contract>[].obs;
  final selectedContractId = Rxn<String>();

  // Status
  final selectedStatus = 'nonaktif'.obs;

  // Edit mode
  final isEditMode = false.obs;
  Tenant? editingTenant;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    _loadAvailableContracts();

    // Check if editing
    if (Get.arguments != null && Get.arguments is Tenant) {
      _initEditMode(Get.arguments as Tenant);
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    nikController.dispose();
    addressController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Load available contracts for selection
  Future<void> _loadAvailableContracts() async {
    try {
      isLoading.value = true;
      
      // Fetch all active contracts
      final response = await _supabaseService.client
          .from('contracts')
          .select('*, tenants:tenants!contracts_tenant_id_fkey(name), rooms:rooms!contracts_room_id_fkey(room_number)')
          .eq('status', 'aktif')
          .order('created_at', ascending: false);
      
      final allContracts = (response as List)
          .map((json) => Contract.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Filter to get contracts without tenants (for new tenant)
      // or contracts that belong to the tenant being edited
      if (isEditMode.value && editingTenant?.contractId != null) {
        // In edit mode, include the current contract
        availableContracts.value = allContracts.where((contract) {
          // Get tenant info from the contract join
          final tenants = contract.tenantName;
          return tenants == null || tenants.isEmpty || contract.id == editingTenant!.contractId;
        }).toList();
      } else {
        // In create mode, only show contracts without tenants
        availableContracts.value = allContracts.where((contract) {
          final tenants = contract.tenantName;
          return tenants == null || tenants.isEmpty;
        }).toList();
      }
      
      print('📋 Loaded ${availableContracts.length} available contracts');
    } catch (e) {
      print('❌ Error loading available contracts: $e');
      errorMessage.value = 'Gagal memuat kontrak: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Initialize edit mode with existing tenant data
  void _initEditMode(Tenant tenant) {
    isEditMode.value = true;
    editingTenant = tenant;

    nameController.text = tenant.name;
    phoneController.text = tenant.phone;
    nikController.text = tenant.nik ?? '';
    addressController.text = tenant.address ?? '';
    selectedContractId.value = tenant.contractId;
    selectedStatus.value = tenant.status;
    existingPhotoUrl.value = tenant.photoUrl;
  }

  /// Pick photo from gallery
  Future<void> pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedPhoto.value = image;
        photoBytes.value = await image.readAsBytes();
        removeExistingPhoto.value = false;
      }
    } catch (e) {
      print('❌ Error picking photo: $e');
      Get.snackbar(
        'Error',
        'Gagal memilih foto: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedPhoto.value = image;
        photoBytes.value = await image.readAsBytes();
        removeExistingPhoto.value = false;
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      Get.snackbar(
        'Error',
        'Gagal mengambil foto: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  /// Remove selected/existing photo
  void removePhoto() {
    selectedPhoto.value = null;
    photoBytes.value = null;
    if (existingPhotoUrl.value != null) {
      removeExistingPhoto.value = true;
    }
  }

  /// Set selected contract
  void setContract(String? contractId) {
    selectedContractId.value = contractId;
  }

  /// Set status
  void setStatus(String status) {
    selectedStatus.value = status;
  }

  /// Validate and save form
  Future<void> saveForm() async {
    if (!formKey.currentState!.validate()) return;
    
    // Contract selection is optional now
    // if (selectedContractId.value == null) { ... }

    try {
      isSaving.value = true;
      errorMessage.value = '';

      if (isEditMode.value) {
        await _updateTenant();
      } else {
        await _createTenant();
      }

      Get.back();
      Get.snackbar(
        'Berhasil',
        isEditMode.value
            ? 'Penghuni berhasil diupdate'
            : 'Penghuni baru berhasil ditambahkan',
        backgroundColor: const Color(0xFFB9F3CC),
        colorText: const Color(0xFF2D3748),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Gagal',
        'Terjadi kesalahan: $e',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: const Color(0xFF2D3748),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Create new tenant
  Future<void> _createTenant() async {
    String? userId;
    
    // Create Auth User if email & password provided
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      try {
        userId = await _createAuthUser(
          emailController.text.trim(),
          passwordController.text,
        );
        
        // Create Profile for the new user
        if (userId != null) {
          await _createProfile(userId, nameController.text.trim(), phoneController.text.trim());
        }
      } catch (e) {
        throw 'Gagal membuat akun login: $e';
      }
    }

    final tenant = Tenant(
      id: '', // Will be generated by Supabase
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      nik: nikController.text.trim().isEmpty ? null : nikController.text.trim(),
      address: addressController.text.trim().isEmpty
          ? null
          : addressController.text.trim(),
      contractId: selectedContractId.value,
      status: selectedStatus.value,
      createdAt: DateTime.now(),
      userId: userId,
    );

    await _supabaseService.createTenant(tenant, photo: selectedPhoto.value);
  }

  /// Create Auth User using temporary client
  Future<String?> _createAuthUser(String email, String password) async {
    print('👤 Creating auth user for email: "$email"');
    
    // Use a temporary client to avoid replacing the current admin session
    var supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      throw 'Konfigurasi Supabase tidak ditemukan di .env';
    }

    // Remove trailing slash if present
    if (supabaseUrl.endsWith('/')) {
      supabaseUrl = supabaseUrl.substring(0, supabaseUrl.length - 1);
    }

    print('🔗 Supabase Auth URL: $supabaseUrl/auth/v1');
    print('📧 Email Code Units: ${email.codeUnits}');

    // Use GoTrueClient directly to avoid SupabaseClient's storage requirements
    final authClient = GoTrueClient(
      url: '$supabaseUrl/auth/v1',
      headers: {
        'apikey': supabaseKey,
        // 'Authorization': 'Bearer $supabaseKey', // Let GoTrueClient handle this or use apikey
      },
      flowType: AuthFlowType.pkce,
      asyncStorage: const MemoryStorage(),
    );

    final response = await authClient.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw 'Gagal mendapatkan User ID dari Supabase';
    }

    return response.user!.id;
  }

  /// Create Profile for the new user
  Future<void> _createProfile(String userId, String name, String phone) async {
    // Use upsert to handle cases where a trigger might have already created the profile
    await _supabaseService.client.from('profiles').upsert({
      'id': userId,
      'full_name': name,
      'phone': phone,
      'role': 'tenant',
      'avatar_url': 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
    });
  }

  /// Update existing tenant
  Future<void> _updateTenant() async {
    final tenant = Tenant(
      id: editingTenant!.id,
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      nik: nikController.text.trim().isEmpty ? null : nikController.text.trim(),
      address: addressController.text.trim().isEmpty
          ? null
          : addressController.text.trim(),
      photoUrl: removeExistingPhoto.value ? null : existingPhotoUrl.value,
      contractId: selectedContractId.value,
      status: selectedStatus.value,
      createdAt: editingTenant!.createdAt,
    );

    await _supabaseService.updateTenant(
      tenant,
      newPhoto: selectedPhoto.value,
      removePhoto: removeExistingPhoto.value,
    );
  }

  /// Check if has photo
  bool get hasPhoto =>
      selectedPhoto.value != null ||
      (existingPhotoUrl.value != null && !removeExistingPhoto.value);

  /// Get photo widget data
  String? get displayPhotoUrl {
    if (removeExistingPhoto.value) return null;
    return existingPhotoUrl.value;
  }

  /// Get selected contract details
  Contract? get selectedContract {
    if (selectedContractId.value == null) return null;
    try {
      return availableContracts.firstWhere(
        (c) => c.id == selectedContractId.value,
      );
    } catch (e) {
      return null;
    }
  }

  /// Status options
  List<Map<String, String>> get statusOptions => [
    {'value': 'nonaktif', 'label': 'Nonaktif'},
    {'value': 'aktif', 'label': 'Aktif'},
    {'value': 'keluar', 'label': 'Keluar'},
  ];
}

class MemoryStorage implements GotrueAsyncStorage {
  static final Map<String, String> _storage = {};
  
  const MemoryStorage();

  @override
  Future<String?> getItem({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _storage.remove(key);
  }
}
