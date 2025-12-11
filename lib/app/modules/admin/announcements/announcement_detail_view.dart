import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/announcement_model.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'announcements_controller.dart';

/// Announcement Detail View
class AnnouncementDetailView extends StatefulWidget {
  const AnnouncementDetailView({Key? key}) : super(key: key);

  @override
  State<AnnouncementDetailView> createState() => _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<AnnouncementDetailView>
    with SingleTickerProviderStateMixin {
  Announcement? _announcement;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArguments();
  }

  void _loadArguments() {
    final args = Get.arguments;
    if (args != null && args is Announcement) {
      _announcement = args;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_announcement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengumuman')),
        body: const Center(child: Text('Pengumuman tidak ditemukan')),
      );
    }

    final announcement = _announcement!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          _buildSliverAppBar(announcement),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and badges
                  _buildTitleSection(announcement),
                  const SizedBox(height: 24),

                  // Content section
                  _buildContentSection(announcement),
                  const SizedBox(height: 24),

                  // Attachments section
                  if (announcement.hasAttachments) ...[
                    _buildAttachmentsSection(announcement),
                    const SizedBox(height: 24),
                  ],

                  // Read tracking section
                  _buildReadTrackingSection(announcement),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildActionButtons(announcement),
    );
  }

  Widget _buildSliverAppBar(Announcement announcement) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
        ),
        onPressed: () => Get.back(result: true),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.pastelBlue.withOpacity(0.3),
                AppTheme.softGreen.withOpacity(0.3),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.campaign,
              size: 48,
              color: AppTheme.pastelBlue.withOpacity(0.5),
            ),
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.more_vert, size: 20, color: Colors.black87),
          ),
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Get.toNamed(
                AppRoutes.ADMIN_ANNOUNCEMENT_FORM,
                arguments: announcement,
              );
              if (result == true) {
                // Refresh and go back to list
                Get.back(result: true);
              }
            } else if (value == 'delete') {
              _showDeleteConfirmation(announcement);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTitleSection(Announcement announcement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Badges
          Row(
            children: [
              if (announcement.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.softPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.priority_high,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Wajib Dibaca',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              if (announcement.hasAttachments) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${announcement.attachments.length} Lampiran',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            announcement.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Meta info
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                announcement.formattedCreatedAt,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.visibility, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                '${announcement.totalReaders} penghuni sudah membaca',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(Announcement announcement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.pastelBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.article,
                  color: AppTheme.pastelBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Isi Pengumuman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            announcement.content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(Announcement announcement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warmPeach.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_file,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lampiran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: announcement.attachments.length,
            itemBuilder: (context, index) {
              final url = announcement.attachments[index];
              return GestureDetector(
                onTap: () => _openImage(url),
                child: Container(
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
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadTrackingSection(Announcement announcement) {
    // Ensure controller is registered
    if (!Get.isRegistered<AnnouncementsController>()) {
      Get.put(AnnouncementsController());
    }
    final controller = Get.find<AnnouncementsController>();
    final unreadTenants = controller.getUnreadTenants(announcement);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.visibility,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Status Pembacaan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${announcement.totalReaders}/${controller.tenants.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: AppTheme.pastelBlue,
              unselectedLabelColor: Colors.grey.shade600,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 6),
                      Text('Sudah Baca (${announcement.totalReaders})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 6),
                      Text('Belum Baca (${unreadTenants.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Already read
                _buildReadList(announcement.readBy),
                // Not yet read
                _buildUnreadList(unreadTenants),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadList(List<AnnouncementRead> reads) {
    if (reads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Belum ada yang membaca',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: reads.length,
      itemBuilder: (context, index) {
        final read = reads[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.softGreen.withOpacity(0.2),
            backgroundImage: read.tenantPhoto != null
                ? CachedNetworkImageProvider(read.tenantPhoto!)
                : null,
            child: read.tenantPhoto == null
                ? Text(
                    read.tenantName?.substring(0, 1).toUpperCase() ?? '?',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            read.tenantName ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Kamar ${read.roomNumber ?? '-'} • ${read.formattedReadAt}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: Icon(
            Icons.check_circle,
            color: Colors.green.shade400,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildUnreadList(List unreadTenants) {
    if (unreadTenants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
            const SizedBox(height: 12),
            Text(
              'Semua penghuni sudah membaca',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: unreadTenants.length,
      itemBuilder: (context, index) {
        final tenant = unreadTenants[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.warmPeach.withOpacity(0.2),
            backgroundImage: tenant.photoUrl != null
                ? CachedNetworkImageProvider(tenant.photoUrl!)
                : null,
            child: tenant.photoUrl == null
                ? Text(
                    tenant.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            tenant.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Kamar ${tenant.roomNumber ?? '-'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          trailing: Icon(
            Icons.schedule,
            color: Colors.orange.shade400,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Announcement announcement) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA9C9FF), Color(0xFFB9F3CC)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA9C9FF).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'edit_announcement_fab',
            onPressed: () async {
              final result = await Get.toNamed(
                AppRoutes.ADMIN_ANNOUNCEMENT_FORM,
                arguments: announcement,
              );
              if (result == true) {
                Get.back(result: true);
              }
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  void _openImage(String url) async {
    // Open image in full screen or browser
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteConfirmation(Announcement announcement) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text(
          'Anda yakin ingin menghapus pengumuman "${announcement.title}"?\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              // Ensure controller is registered
              if (!Get.isRegistered<AnnouncementsController>()) {
                Get.put(AnnouncementsController());
              }
              final controller = Get.find<AnnouncementsController>();
              final success = await controller.deleteAnnouncement(announcement);
              if (success) {
                Get.back(result: true); // Close detail view and signal refresh
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
