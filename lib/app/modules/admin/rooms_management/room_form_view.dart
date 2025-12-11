import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/room_model.dart';
import '../../../theme/app_theme.dart';
import 'room_form_controller.dart';

/// Room Form View for Add/Edit Room
class RoomFormView extends GetView<RoomFormController> {
  const RoomFormView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: _buildAppBar(),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Section
              _buildPhotoSection(),
              const SizedBox(height: 24),

              // Room Info Card
              _buildInfoCard(),
              const SizedBox(height: 24),

              // Facilities Section
              _buildFacilitiesSection(),
              const SizedBox(height: 24),

              // Description Section
              _buildDescriptionSection(),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () => Get.back(),
      ),
      title: Obx(
        () => Text(
          controller.isEditMode.value ? 'Edit Kamar' : 'Tambah Kamar Baru',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.selectedGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Foto Kamar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Tambahkan foto untuk menampilkan kamar',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 16),

        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Photo Grid
                if (controller.existingPhotos.isNotEmpty ||
                    controller.newPhotos.isNotEmpty)
                  _buildPhotoGrid(),

                // Add Photo Button
                InkWell(
                  onTap: () => _showPhotoSourceDialog(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.pastelBlue.withOpacity(0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.pastelBlue.withOpacity(0.2),
                                AppTheme.softGreen.withOpacity(0.2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: AppTheme.pastelBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tambah Foto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kamera atau Galeri',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Existing photos from server
          ...controller.existingPhotos.map(
            (url) => _buildPhotoTile(
              imageUrl: url,
              onDelete: () => controller.removeExistingPhoto(url),
            ),
          ),
          // New photos from device
          ...controller.newPhotos.map(
            (file) => _buildPhotoTile(
              file: file,
              onDelete: () => controller.removeNewPhoto(file),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile({
    String? imageUrl,
    XFile? file,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.error),
                    ),
                  )
                : FutureBuilder<Uint8List>(
                    future: file!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.error),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoSourceDialog() {
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    color: AppTheme.pastelBlue,
                    onTap: () {
                      Get.back();
                      controller.pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    color: AppTheme.softGreen,
                    onTap: () {
                      Get.back();
                      controller.pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.selectedGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Kamar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Room Number
          _buildTextField(
            controller: controller.roomNumberController,
            label: 'Nomor Kamar',
            hint: 'Contoh: 101, 102, A1',
            icon: Icons.door_front_door,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor kamar wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Price
          _buildTextField(
            controller: controller.priceController,
            label: 'Harga per Bulan',
            hint: 'Contoh: 1500000',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefix: 'Rp ',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Harga wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Status Dropdown
          _buildStatusDropdown(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefix,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppTheme.pastelBlue),
            prefixText: prefix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.pastelBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Kamar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedStatus.value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.pastelBlue,
                ),
                items: [
                  _buildDropdownItem(
                    'kosong',
                    'Kosong',
                    Icons.check_circle,
                    const Color(0xFF4CAF50),
                  ),
                  _buildDropdownItem(
                    'terisi',
                    'Terisi',
                    Icons.person,
                    const Color(0xFFE91E63),
                  ),
                  _buildDropdownItem(
                    'maintenance',
                    'Maintenance',
                    Icons.build,
                    const Color(0xFFFF9800),
                  ),
                ],
                onChanged: (value) => controller.selectedStatus.value = value!,
              ),
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    final facilities = [
      {'name': 'AC', 'icon': Icons.ac_unit},
      {'name': 'Wifi', 'icon': Icons.wifi},
      {'name': 'Kamar Mandi Dalam', 'icon': Icons.bathroom},
      {'name': 'Kasur', 'icon': Icons.bed},
      {'name': 'Lemari', 'icon': Icons.door_sliding},
      {'name': 'Meja Belajar', 'icon': Icons.desk},
      {'name': 'Kursi', 'icon': Icons.chair},
      {'name': 'TV', 'icon': Icons.tv},
      {'name': 'Kulkas', 'icon': Icons.kitchen},
      {'name': 'Dapur', 'icon': Icons.soup_kitchen},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.selectedGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.checklist,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Fasilitas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih fasilitas yang tersedia',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),

          Obx(
            () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: facilities.map((f) {
                final isSelected = controller.selectedFacilities.contains(
                  f['name'],
                );
                return InkWell(
                  onTap: () => controller.toggleFacility(f['name'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppTheme.selectedGradient : null,
                      color: isSelected ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          f['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          f['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.selectedGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Deskripsi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller.descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Deskripsikan kamar ini...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.pastelBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: controller.isLoading.value
              ? LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade400],
                )
              : const LinearGradient(
                  colors: [Color(0xFFA9C9FF), Color(0xFFB9F3CC)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: controller.isLoading.value
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFA9C9FF).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.saveRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      controller.isEditMode.value ? Icons.save : Icons.add,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isEditMode.value
                          ? 'Simpan Perubahan'
                          : 'Tambah Kamar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
