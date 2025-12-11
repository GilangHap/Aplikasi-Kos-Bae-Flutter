import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/announcement_model.dart';
import '../../../theme/app_theme.dart';
import 'announcements_controller.dart';

/// Announcement Form View for creating/editing announcements
class AnnouncementFormView extends StatefulWidget {
  const AnnouncementFormView({Key? key}) : super(key: key);

  @override
  State<AnnouncementFormView> createState() => _AnnouncementFormViewState();
}

class _AnnouncementFormViewState extends State<AnnouncementFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isRequired = false;
  bool _isLoading = false;

  Announcement? _announcement;
  bool get _isEditing => _announcement != null;

  // Attachments
  List<String> _existingAttachments = [];
  List<String> _removedAttachments = [];
  List<XFile> _newAttachments = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadArguments();
  }

  void _loadArguments() {
    final args = Get.arguments;
    if (args != null && args is Announcement) {
      _announcement = args;
      _titleController.text = args.title;
      _contentController.text = args.content;
      _isRequired = args.isRequired;
      _existingAttachments = List.from(args.attachments);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              _buildSectionLabel('Judul Pengumuman', true),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hintText: 'Masukkan judul pengumuman',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  if (value.length < 5) {
                    return 'Judul minimal 5 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Content field
              _buildSectionLabel('Isi Pengumuman', true),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _contentController,
                hintText: 'Masukkan isi pengumuman...',
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Isi pengumuman tidak boleh kosong';
                  }
                  if (value.length < 10) {
                    return 'Isi pengumuman minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Is Required toggle
              _buildSectionLabel('Opsi Pengumuman', false),
              const SizedBox(height: 8),
              _buildRequiredToggle(),
              const SizedBox(height: 24),

              // Attachments
              _buildSectionLabel('Lampiran (Opsional)', false),
              const SizedBox(height: 8),
              _buildAttachmentsSection(),
              const SizedBox(height: 32),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        _isEditing ? 'Edit Pengumuman' : 'Buat Pengumuman',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSectionLabel(String label, bool required) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRequiredToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.softPink.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.priority_high,
              color: Colors.red.shade400,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wajib Dibaca',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tandai jika pengumuman ini penting dan wajib dibaca oleh semua penghuni',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _isRequired,
            onChanged: (value) {
              setState(() {
                _isRequired = value;
              });
            },
            activeColor: AppTheme.pastelBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add attachment button
          InkWell(
            onTap: _pickAttachment,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.pastelBlue.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.pastelBlue.withOpacity(0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: AppTheme.pastelBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Tambah Lampiran',
                    style: TextStyle(
                      color: AppTheme.pastelBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Existing attachments
          if (_existingAttachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Lampiran Tersimpan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _existingAttachments.map((url) {
                return _buildAttachmentItem(
                  url: url,
                  onRemove: () {
                    setState(() {
                      _existingAttachments.remove(url);
                      _removedAttachments.add(url);
                    });
                  },
                );
              }).toList(),
            ),
          ],

          // New attachments
          if (_newAttachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Lampiran Baru',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _newAttachments.map((file) {
                return _buildNewAttachmentItem(
                  file: file,
                  onRemove: () {
                    setState(() {
                      _newAttachments.remove(file);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentItem({
    required String url,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade100,
                child: Icon(Icons.broken_image, color: Colors.grey.shade400),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewAttachmentItem({
    required XFile file,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.pastelBlue.withOpacity(0.5)),
            color: AppTheme.pastelBlue.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, color: AppTheme.pastelBlue, size: 32),
              const SizedBox(height: 4),
              Text(
                'New',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.pastelBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFFA9C9FF), Color(0xFFB9F3CC)],
              ),
        color: _isLoading ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFA9C9FF).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditing ? Icons.save : Icons.send,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditing ? 'Simpan Perubahan' : 'Buat Pengumuman',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        setState(() {
          _newAttachments.addAll(images);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memilih file: $e',
        backgroundColor: const Color(0xFFF7C4D4),
        colorText: Colors.black87,
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure controller is registered
      if (!Get.isRegistered<AnnouncementsController>()) {
        Get.put(AnnouncementsController());
      }
      final controller = Get.find<AnnouncementsController>();
      bool success;

      if (_isEditing) {
        success = await controller.updateAnnouncement(
          id: _announcement!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isRequired: _isRequired,
          existingAttachments: _existingAttachments,
          newAttachments: _newAttachments.isNotEmpty ? _newAttachments : null,
          removedAttachments: _removedAttachments.isNotEmpty
              ? _removedAttachments
              : null,
        );
      } else {
        success = await controller.createAnnouncement(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isRequired: _isRequired,
          attachments: _newAttachments.isNotEmpty ? _newAttachments : null,
        );
      }

      if (success) {
        // Data sudah di-refresh oleh createAnnouncement/updateAnnouncement
        // Langsung kembali ke list
        Get.back(result: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
