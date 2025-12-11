import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import 'tenant_form_controller.dart';

/// Add/Edit Tenant Form View
class TenantFormView extends GetView<TenantFormController> {
  const TenantFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.softGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.close_rounded, color: AppTheme.charcoal),
            onPressed: () => Get.back(),
          ),
        ),
        title: Obx(
          () => Text(
            controller.isEditMode.value ? 'Edit Penghuni' : 'Tambah Penghuni',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.deepBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => controller.isSaving.value
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  )
                : TextButton.icon(
                    onPressed: controller.saveForm,
                    icon: Icon(Icons.save_rounded, color: AppTheme.primaryBlue),
                    label: Text(
                      'Simpan',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo Section
                _buildPhotoSection(),
                const SizedBox(height: 32),

                // Personal Info Section
                _buildSectionHeader(
                  'Informasi Pribadi',
                  Icons.person_rounded,
                  AppTheme.primaryBlue,
                ),
                const SizedBox(height: 16),
                _buildPersonalInfoFields(),
                const SizedBox(height: 32),

                // Login Info Section (Only for new tenants)
                if (!controller.isEditMode.value) ...[
                  _buildSectionHeader(
                    'Akun Login',
                    Icons.lock_rounded,
                    AppTheme.gold,
                  ),
                  const SizedBox(height: 16),
                  _buildLoginInfoFields(),
                  const SizedBox(height: 32),
                ],

                // Contract Section
                _buildSectionHeader(
                  'Kontrak & Status',
                  Icons.description_rounded,
                  AppTheme.lightBlue,
                ),
                const SizedBox(height: 16),
                _buildContractStatusFields(),
                const SizedBox(height: 40),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Photo section with upload capability
  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          Obx(() {
            final hasNewPhoto = controller.photoBytes.value != null;
            final hasExistingPhoto = controller.displayPhotoUrl != null;

            return Stack(
              children: [
                // Photo container
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryBlue, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: hasNewPhoto
                        ? Image.memory(
                            controller.photoBytes.value!,
                            fit: BoxFit.cover,
                          )
                        : hasExistingPhoto
                        ? CachedNetworkImage(
                            imageUrl: controller.displayPhotoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildPhotoPlaceholder(),
                          )
                        : _buildPhotoPlaceholder(),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPhotoButton(
                icon: Icons.photo_library_rounded,
                label: 'Galeri',
                onTap: controller.pickPhoto,
              ),
              const SizedBox(width: 12),
              _buildPhotoButton(
                icon: Icons.camera_alt_rounded,
                label: 'Kamera',
                onTap: controller.takePhoto,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: AppTheme.primaryBlue.withOpacity(0.2),
      child: Icon(
        Icons.person_rounded,
        size: 64,
        color: AppTheme.primaryBlue.withOpacity(0.5),
      ),
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.deepBlue.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.deepBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.deepBlue,
          ),
        ),
      ],
    );
  }

  /// Personal info fields
  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        // Name field
        _buildTextField(
          controller: controller.nameController,
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap',
          icon: Icons.person_outline_rounded,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama tidak boleh kosong';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone field
        _buildTextField(
          controller: controller.phoneController,
          label: 'No. Telepon',
          hint: 'Contoh: 081234567890',
          icon: Icons.phone_rounded,
          isRequired: true,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'No. telepon tidak boleh kosong';
            }
            if (value.length < 10) {
              return 'No. telepon minimal 10 digit';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // NIK field
        _buildTextField(
          controller: controller.nikController,
          label: 'NIK (Opsional)',
          hint: 'Masukkan 16 digit NIK',
          icon: Icons.badge_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
        ),
        const SizedBox(height: 16),

        // Address field
        _buildTextField(
          controller: controller.addressController,
          label: 'Alamat Asal (Opsional)',
          hint: 'Masukkan alamat lengkap',
          icon: Icons.home_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  /// Login info fields
  Widget _buildLoginInfoFields() {
    return Column(
      children: [
        // Email field
        _buildTextField(
          controller: controller.emailController,
          label: 'Email',
          hint: 'Masukkan email untuk login',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!GetUtils.isEmail(value)) {
                return 'Format email tidak valid';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password field
        Obx(
          () => _buildTextField(
            controller: controller.passwordController,
            label: 'Password',
            hint: 'Masukkan password',
            icon: Icons.lock_rounded,
            obscureText: controller.obscurePassword.value,
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppTheme.charcoal.withOpacity(0.5),
              ),
              onPressed: () => controller.obscurePassword.toggle(),
            ),
            validator: (value) {
              if (controller.emailController.text.isNotEmpty) {
                if (value == null || value.isEmpty) {
                  return 'Password wajib diisi jika email diisi';
                }
                if (value.length < 6) {
                  return 'Password minimal 6 karakter';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Isi email & password untuk membuatkan akun login bagi penghuni ini.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Contract and status fields
  Widget _buildContractStatusFields() {
    return Column(
      children: [
        // Contract dropdown
        Obx(
          () => _buildDropdownField(
            label: 'Pilih Kontrak',
            hint: 'Pilih kontrak untuk penghuni',
            icon: Icons.description_rounded,
            value: controller.selectedContractId.value,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Belum ada kontrak'),
              ),
              ...controller.availableContracts.map((contract) {
                final room = contract.roomNumber ?? 'N/A';
                final startDate = DateFormat(
                  'dd MMM yyyy',
                ).format(contract.startDate);
                final endDate = DateFormat(
                  'dd MMM yyyy',
                ).format(contract.endDate);
                return DropdownMenuItem<String>(
                  value: contract.id,
                  child: Text(
                    'Kamar $room ($startDate - $endDate)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                );
              }),
            ],
            onChanged: controller.setContract,
          ),
        ),
        const SizedBox(height: 16),

        // Show contract details if selected
        Obx(() {
          final selectedContract = controller.selectedContract;
          if (selectedContract != null) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.lightBlue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Detail Kontrak',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildContractDetailRow(
                    'Kamar',
                    selectedContract.roomNumber ?? '-',
                    Icons.door_sliding_rounded,
                  ),
                  _buildContractDetailRow(
                    'Mulai',
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(selectedContract.startDate),
                    Icons.calendar_today_rounded,
                  ),
                  _buildContractDetailRow(
                    'Berakhir',
                    DateFormat('dd MMM yyyy').format(selectedContract.endDate),
                    Icons.event_rounded,
                  ),
                  _buildContractDetailRow(
                    'Biaya/Bulan',
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(selectedContract.monthlyRent),
                    Icons.payments_rounded,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 16),

        // Status dropdown
        Obx(
          () => _buildDropdownField(
            label: 'Status',
            hint: 'Pilih status penghuni',
            icon: Icons.circle,
            value: controller.selectedStatus.value,
            items: controller.statusOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: option['value'] == 'aktif'
                            ? const Color(0xFF48BB78)
                            : const Color(0xFFE53E3E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(option['label']!),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => controller.setStatus(value!),
          ),
        ),
      ],
    );
  }

  Widget _buildContractDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.charcoal.withOpacity(0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppTheme.deepBlue,
              ),
            ),
            if (isRequired)
              Text(' *', style: TextStyle(color: Colors.red.shade400)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          obscureText: obscureText,
          style: GoogleFonts.plusJakartaSans(color: AppTheme.deepBlue),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppTheme.charcoal.withOpacity(0.4),
            ),
            prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.mediumGrey.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Dropdown field builder
  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: AppTheme.deepBlue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.mediumGrey.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(
                hint,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.charcoal.withOpacity(0.4),
                ),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.primaryBlue,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Submit button
  Widget _buildSubmitButton() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: controller.isSaving.value
                ? [AppTheme.mediumGrey, AppTheme.mediumGrey]
                : [AppTheme.primaryBlue, AppTheme.lightBlue],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: controller.isSaving.value
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: controller.isSaving.value ? null : controller.saveForm,
          icon: controller.isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  controller.isEditMode.value
                      ? Icons.save_rounded
                      : Icons.person_add_rounded,
                ),
          label: Text(
            controller.isSaving.value
                ? 'Menyimpan...'
                : controller.isEditMode.value
                ? 'Simpan Perubahan'
                : 'Tambah Penghuni',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
