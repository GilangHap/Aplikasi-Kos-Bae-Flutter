// FILE: lib/app/modules/admin/announcements/announcements_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/announcement_model.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'announcements_controller.dart';

/// Admin Announcements Management View
class AdminAnnouncementsView extends StatelessWidget {
  const AdminAnnouncementsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<AnnouncementsController>()) {
      Get.put(AnnouncementsController());
    }
    final controller = Get.find<AnnouncementsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppTheme.pastelBlue,
        child: CustomScrollView(
          slivers: [
            // Statistics Cards
            SliverToBoxAdapter(child: _buildStatisticsSection(controller)),

            // Search & Filter Bar
            SliverToBoxAdapter(child: _buildSearchBar(controller)),

            // Filter Chips
            SliverToBoxAdapter(child: _buildFilterChips(controller)),

            // Announcements List
            Obx(() {
              if (controller.isLoading.value &&
                  controller.announcements.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.errorMessage.value.isNotEmpty &&
                  controller.announcements.isEmpty) {
                return SliverFillRemaining(child: _buildErrorState(controller));
              }

              if (controller.filteredAnnouncements.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(controller));
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final announcement =
                        controller.filteredAnnouncements[index];
                    return _buildAnnouncementCard(announcement, controller);
                  }, childCount: controller.filteredAnnouncements.length),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildStatisticsSection(AnnouncementsController controller) {
    return Obx(() {
      final stats = controller.statistics;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manajemen Pengumuman',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats['total']} total pengumuman',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats cards
            Row(
              children: [
                _buildStatCard(
                  'Wajib',
                  '${stats['required']}',
                  'Pengumuman',
                  AppTheme.softPink,
                  Icons.priority_high,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Opsional',
                  '${stats['optional']}',
                  'Pengumuman',
                  AppTheme.pastelBlue,
                  Icons.info_outline,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Bulan Ini',
                  '${stats['thisMonth']}',
                  'Baru',
                  AppTheme.softGreen,
                  Icons.calendar_month,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String count,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
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
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AnnouncementsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            Icon(Icons.search, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Cari pengumuman...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: controller.onSearchChanged,
              ),
            ),
            Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey.shade400,
                  onPressed: controller.clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(AnnouncementsController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.filterOptions.map((option) {
              final isSelected =
                  controller.selectedFilter.value == option['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(option['label']!),
                  selected: isSelected,
                  onSelected: (_) => controller.setFilter(option['value']!),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.pastelBlue.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppTheme.pastelBlue
                        : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.pastelBlue
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    Announcement announcement,
    AnnouncementsController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Get.toNamed(
              AppRoutes.ADMIN_ANNOUNCEMENT_DETAIL,
              arguments: announcement,
            );
            // Refresh data when returning from detail (might have deleted/edited)
            if (result == true && Get.isRegistered<AnnouncementsController>()) {
              Get.find<AnnouncementsController>().refreshData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badges and actions
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (announcement.isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
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
                                    size: 14,
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
                                horizontal: 8,
                                vertical: 4,
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
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${announcement.attachments.length}',
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
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Get.toNamed(
                            AppRoutes.ADMIN_ANNOUNCEMENT_FORM,
                            arguments: announcement,
                          );
                          // Refresh data when returning from edit form
                          if (result == true &&
                              Get.isRegistered<AnnouncementsController>()) {
                            Get.find<AnnouncementsController>().refreshData();
                          }
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(announcement, controller);
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
                              Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  announcement.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Content preview
                Text(
                  announcement.contentPreview,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 16),

                // Footer with date and read count
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      announcement.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.softGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${announcement.totalReaders} dibaca',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
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
        heroTag: 'announcements_fab',
        onPressed: () async {
          final result = await Get.toNamed(AppRoutes.ADMIN_ANNOUNCEMENT_FORM);
          // Refresh data when returning from form
          if (result == true && Get.isRegistered<AnnouncementsController>()) {
            Get.find<AnnouncementsController>().refreshData();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Buat Pengumuman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Widget _buildErrorState(AnnouncementsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage.value,
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AnnouncementsController controller) {
    final isFiltered =
        controller.selectedFilter.value != 'all' ||
        controller.searchQuery.value.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.campaign_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'Tidak ada hasil' : 'Belum ada pengumuman',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Buat pengumuman pertama untuk penghuni',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: controller.clearFilters,
              child: const Text('Reset Filter'),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    Announcement announcement,
    AnnouncementsController controller,
  ) {
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
            onPressed: () {
              Get.back();
              controller.deleteAnnouncement(announcement);
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
