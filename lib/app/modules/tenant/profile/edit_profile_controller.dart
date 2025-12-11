import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/supabase_service.dart';
import '../../../models/tenant_model.dart';

/// Controller for tenant profile editing
class EditProfileController extends GetxController {
  final _supabaseService = Get.find<SupabaseService>();
  final _authService = Get.find<AuthService>();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final nikController = TextEditingController();
  final addressController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();

  // State
  final tenant = Rxn<Tenant>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final isChangingPassword = false.obs;
  final selectedPhoto = Rxn<XFile>();
  final removePhoto = false.obs;

  // Password visibility
  final showCurrentPassword = false.obs;
  final showNewPassword = false.obs;
  final showConfirmPassword = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    nikController.dispose();
    addressController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Load current tenant profile
  Future<void> loadProfile() async {
    try {
      isLoading.value = true;
      final tenantId = await _authService.getCurrentTenantId();
      if (tenantId != null) {
        final tenantData = await _supabaseService.getTenantById(tenantId);
        if (tenantData != null) {
          tenant.value = tenantData;
          _populateFormFields(tenantData);
        }
      }
    } catch (e) {
      print('❌ Error loading profile: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat data profil',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Populate form fields with tenant data
  void _populateFormFields(Tenant tenant) {
    nameController.text = tenant.name;
    phoneController.text = tenant.phone;
    nikController.text = tenant.nik ?? '';
    addressController.text = tenant.address ?? '';
  }

  /// Pick photo from gallery
  Future<void> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        selectedPhoto.value = image;
        removePhoto.value = false;
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Gagal memilih gambar',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Take photo from camera
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
        removePhoto.value = false;
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      Get.snackbar(
        'Error',
        'Gagal mengambil foto',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Remove current photo
  void clearPhoto() {
    selectedPhoto.value = null;
    if (tenant.value?.photoUrl != null) {
      removePhoto.value = true;
    }
  }

  /// Save profile changes
  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    if (tenant.value == null) return;

    try {
      isSaving.value = true;
      
      await _supabaseService.updateTenantProfile(
        tenantId: tenant.value!.id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        nik: nikController.text.trim().isNotEmpty ? nikController.text.trim() : null,
        address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
        newPhoto: selectedPhoto.value,
        removePhoto: removePhoto.value,
      );

      Get.snackbar(
        'Berhasil',
        'Profil berhasil diperbarui',
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Clear photo selection after save
      selectedPhoto.value = null;
      removePhoto.value = false;

      // Refresh profile
      await loadProfile();
    } catch (e) {
      print('❌ Error saving profile: $e');
      Get.snackbar(
        'Error',
        'Gagal menyimpan profil',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Change password
  Future<void> changePassword() async {
    if (!passwordFormKey.currentState!.validate()) return;

    try {
      isChangingPassword.value = true;

      // Verify new password matches confirmation
      if (newPasswordController.text != confirmPasswordController.text) {
        Get.snackbar(
          'Error',
          'Password baru dan konfirmasi tidak cocok',
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final success = await _authService.changePassword(newPasswordController.text);

      if (success) {
        // Clear password fields
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        Get.snackbar(
          'Berhasil',
          'Password berhasil diubah',
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Gagal mengubah password',
          backgroundColor: Colors.red.shade400,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ Error changing password: $e');
      Get.snackbar(
        'Error',
        'Gagal mengubah password',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isChangingPassword.value = false;
    }
  }

  /// Validate name field
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }
    return null;
  }

  /// Validate phone field
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return 'Nomor telepon hanya boleh angka';
    }
    if (value.trim().length < 10) {
      return 'Nomor telepon minimal 10 digit';
    }
    return null;
  }

  /// Validate new password
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password baru tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != newPasswordController.text) {
      return 'Password tidak cocok';
    }
    return null;
  }
}
