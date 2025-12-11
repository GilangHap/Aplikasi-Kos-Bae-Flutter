// FILE: lib/app/modules/tenant/complaints/tenant_complaints_view.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import 'tenant_complaints_controller.dart';

/// Tenant complaints view
class TenantComplaintsView extends GetView<TenantComplaintsController> {
  const TenantComplaintsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Premium Header with Logo
          _buildPremiumHeader(),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.fetchComplaints,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.complaints.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 56,
                          color: Colors.green.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tidak Ada Keluhan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Semua fasilitas kamar berfungsi dengan baik.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppTheme.charcoal.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/image/logo_new.png',
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.apartment_rounded,
                              size: 16,
                              color: AppTheme.primaryBlue.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kos Bae',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.complaints.length,
                itemBuilder: (context, index) {
                  final complaint = controller.complaints[index];
                  return _buildComplaintCard(complaint);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateComplaintSheet(context),
        label: const Text('Buat Keluhan'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.pastelBlue,
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.deepBlue, AppTheme.primaryBlue, AppTheme.lightBlue],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/image/logo_new.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.report_problem_rounded,
                    size: 32,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keluhan Saya',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Laporkan kendala dan keluhan Anda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: controller.fetchComplaints,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final status = complaint['status'] as String;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'resolved':
      case 'closed':
        statusColor = AppTheme.softGreen;
        statusLabel = 'Selesai';
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusLabel = 'Diproses';
        statusIcon = Icons.build;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Menunggu';
        statusIcon = Icons.access_time_filled;
    }

    // Parse media
    String? firstPhotoUrl;
    if (complaint['media'] != null) {
      final mediaList = complaint['media'] as List;
      if (mediaList.isNotEmpty) {
        firstPhotoUrl = mediaList.first.toString();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => controller.showComplaintDetail(complaint),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(DateTime.parse(complaint['created_at'])),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint['title'] ?? 'Tanpa Judul',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complaint['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              if (firstPhotoUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstPhotoUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateComplaintSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final Rx<XFile?> selectedPhoto = Rx<XFile?>(null);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buat Keluhan Baru',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Keluhan',
                  hintText: 'Contoh: AC Bocor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Masalah',
                  hintText: 'Jelaskan detail masalah yang Anda alami...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto Bukti (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() {
                if (selectedPhoto.value != null) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder<Uint8List>(
                          future: selectedPhoto.value!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.error),
                              );
                            }
                            return Image.memory(
                              snapshot.data!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => selectedPhoto.value = null,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return InkWell(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      selectedPhoto.value = image;
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk upload foto',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () async {
                            if (titleController.text.isEmpty ||
                                descController.text.isEmpty) {
                              Get.snackbar(
                                'Error',
                                'Judul dan deskripsi wajib diisi',
                              );
                              return;
                            }

                            final success = await controller.createComplaint(
                              title: titleController.text,
                              description: descController.text,
                              photo: selectedPhoto.value,
                            );

                            if (success) {
                              Get.back(); // Close sheet
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.pastelBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSubmitting.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Kirim Keluhan'),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom padding
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
