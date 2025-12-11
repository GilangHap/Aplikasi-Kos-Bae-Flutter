import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../models/announcement_model.dart';
import 'tenant_announcements_controller.dart';

/// Tenant Announcements View - Shows all announcements for tenants
class TenantAnnouncementsView extends GetView<TenantAnnouncementsController> {
  const TenantAnnouncementsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }

        if (controller.announcements.isEmpty) {
          return _buildEmptyState();
        }

        return _buildAnnouncementsList();
      }),
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
            color: AppTheme.softGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.charcoal),
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Pengumuman',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.charcoal,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.softGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded, size: 20, color: AppTheme.charcoal),
          ),
          onPressed: controller.refreshData,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(
            'Memuat pengumuman...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Pengumuman',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pengumuman dari admin akan muncul di sini',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.announcements.length,
        itemBuilder: (context, index) {
          final announcement = controller.announcements[index];
          return _buildAnnouncementCard(announcement);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    
    return GestureDetector(
      onTap: () {
        controller.markAsRead(announcement.id);
        _showAnnouncementDetail(announcement);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and required badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    announcement.isRequired
                        ? Icons.priority_high_rounded
                        : Icons.campaign_rounded,
                    color: announcement.isRequired ? Colors.orange : AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(announcement.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.charcoal.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (announcement.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Penting',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Content preview
            Text(
              announcement.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.charcoal.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            // Attachments indicator
            if (announcement.hasAttachments) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.charcoal.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text(
                    '${announcement.attachments.length} lampiran',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.charcoal.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDetail(Announcement announcement) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            announcement.isRequired
                                ? Icons.priority_high_rounded
                                : Icons.campaign_rounded,
                            color: announcement.isRequired ? Colors.orange : AppTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(announcement.createdAt),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.charcoal.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Full content
                    Text(
                      announcement.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.charcoal.withOpacity(0.8),
                        height: 1.7,
                      ),
                    ),
                    // Attachments
                    if (announcement.hasAttachments) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Lampiran',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoal,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...announcement.attachments.map((url) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.softGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.file_present_rounded, color: AppTheme.primaryBlue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                url.split('/').last,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
