import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import 'edit_profile_controller.dart';

/// Modern Edit Profile View with premium UI
class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, 
              color: AppTheme.charcoal, size: 18),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoader();
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              _buildPhotoSection(),
              const SizedBox(height: 32),

              // Personal Info Section
              _buildSectionTitle('Informasi Pribadi', Icons.person_rounded),
              const SizedBox(height: 16),
              _buildPersonalInfoForm(),
              const SizedBox(height: 32),

              // Change Password Section
              _buildSectionTitle('Ganti Password', Icons.lock_rounded),
              const SizedBox(height: 16),
              _buildPasswordForm(),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  /// Loading indicator
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data...',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Section title with icon
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.1),
                AppTheme.lightBlue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  /// Profile photo section with change option
  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showPhotoOptions(),
            child: Stack(
              children: [
                // Avatar container
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.lightBlue,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Obx(() => _buildAvatarContent()),
                ),
                // Edit badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ketuk untuk mengubah foto',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.charcoal.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Build avatar content based on state
  Widget _buildAvatarContent() {
    // Show selected new photo - use FutureBuilder to load bytes for cross-platform
    if (controller.selectedPhoto.value != null) {
      return FutureBuilder<Uint8List>(
        future: controller.selectedPhoto.value!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ClipOval(
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: 114,
                height: 114,
              ),
            );
          }
          return Container(
            width: 114,
            height: 114,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    // Show existing photo or removed state
    if (!controller.removePhoto.value && 
        controller.tenant.value?.photoUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: controller.tenant.value!.photoUrl!,
          fit: BoxFit.cover,
          width: 114,
          height: 114,
          placeholder: (context, url) => Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => _buildInitialsAvatar(),
        ),
      );
    }

    // Show initials
    return _buildInitialsAvatar();
  }

  /// Initials avatar
  Widget _buildInitialsAvatar() {
    return Container(
      width: 114,
      height: 114,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          controller.tenant.value?.initials ?? '?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  /// Photo options bottom sheet
  void _showPhotoOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.mediumGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pilih Foto Profil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 24),
            _buildPhotoOption(
              icon: Icons.photo_library_rounded,
              label: 'Pilih dari Galeri',
              onTap: () {
                Get.back();
                controller.pickFromGallery();
              },
            ),
            const SizedBox(height: 12),
            _buildPhotoOption(
              icon: Icons.camera_alt_rounded,
              label: 'Ambil Foto',
              onTap: () {
                Get.back();
                controller.takePhoto();
              },
            ),
            if (controller.tenant.value?.photoUrl != null ||
                controller.selectedPhoto.value != null) ...[
              const SizedBox(height: 12),
              _buildPhotoOption(
                icon: Icons.delete_rounded,
                label: 'Hapus Foto',
                color: Colors.red.shade400,
                onTap: () {
                  Get.back();
                  controller.clearPhoto();
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Photo option item
  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryBlue).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (color ?? AppTheme.primaryBlue).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryBlue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color ?? AppTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color ?? AppTheme.charcoal,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: (color ?? AppTheme.charcoal).withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Personal info form
  Widget _buildPersonalInfoForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: controller.nameController,
              label: 'Nama Lengkap',
              icon: Icons.person_rounded,
              validator: controller.validateName,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.phoneController,
              label: 'Nomor Telepon',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: controller.validatePhone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.nikController,
              label: 'NIK (Opsional)',
              icon: Icons.badge_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.addressController,
              label: 'Alamat Asal (Opsional)',
              icon: Icons.location_on_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            // Save button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.primaryBlue.withOpacity(0.5),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Password form
  Widget _buildPasswordForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: controller.passwordFormKey,
        child: Column(
          children: [
            Obx(() => _buildPasswordField(
              controller: controller.newPasswordController,
              label: 'Password Baru',
              icon: Icons.lock_rounded,
              obscure: !controller.showNewPassword.value,
              onToggle: () => controller.showNewPassword.toggle(),
              validator: controller.validateNewPassword,
            )),
            const SizedBox(height: 16),
            Obx(() => _buildPasswordField(
              controller: controller.confirmPasswordController,
              label: 'Konfirmasi Password Baru',
              icon: Icons.lock_outline_rounded,
              obscure: !controller.showConfirmPassword.value,
              onToggle: () => controller.showConfirmPassword.toggle(),
              validator: controller.validateConfirmPassword,
            )),
            const SizedBox(height: 24),
            // Change password button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isChangingPassword.value
                    ? null
                    : controller.changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.gold.withOpacity(0.5),
                ),
                child: controller.isChangingPassword.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Ganti Password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: AppTheme.charcoal,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppTheme.charcoal.withOpacity(0.5),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 50),
        filled: true,
        fillColor: AppTheme.softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  /// Password field builder
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: AppTheme.charcoal,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppTheme.charcoal.withOpacity(0.5),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: AppTheme.gold, size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 50),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppTheme.charcoal.withOpacity(0.4),
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppTheme.softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
