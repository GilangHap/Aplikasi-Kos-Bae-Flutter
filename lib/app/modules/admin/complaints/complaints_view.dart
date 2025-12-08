// FILE: lib/app/modules/admin/complaints/complaints_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/complaint_model.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'complaints_controller.dart';

/// Admin Complaints Management View
class AdminComplaintsView extends StatelessWidget {
  const AdminComplaintsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<ComplaintsController>()) {
      Get.put(ComplaintsController());
    }
    final controller = Get.find<ComplaintsController>();

    return RefreshIndicator(
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

          // Complaints List
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return SliverFillRemaining(child: _buildErrorState(controller));
            }

            if (controller.filteredComplaints.isEmpty) {
              return SliverFillRemaining(child: _buildEmptyState(controller));
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final complaint = controller.filteredComplaints[index];
                  return _buildComplaintCard(complaint, controller);
                }, childCount: controller.filteredComplaints.length),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ComplaintsController controller) {
    return Obx(() {
      final stats = controller.statistics;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert banner for pending complaints
            if ((stats['submitted'] ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.softPink.withOpacity(0.3),
                      AppTheme.softPink.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.softPink, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.softPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.report_problem,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats['submitted']} Keluhan Baru',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Butuh tindakan segera',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.setStatusFilter('submitted');
                      },
                      child: const Text('Lihat'),
                    ),
                  ],
                ),
              ),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${stats['total']}',
                    'Semua keluhan',
                    AppTheme.pastelBlue,
                    Icons.inbox,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Diajukan',
                    '${stats['submitted']}',
                    'Belum diproses',
                    AppTheme.softPink,
                    Icons.pending,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Diproses',
                    '${stats['inProgress']}',
                    'Sedang ditangani',
                    AppTheme.warmPeach,
                    Icons.engineering,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Selesai',
                    '${stats['resolved']}',
                    'Telah ditangani',
                    AppTheme.softGreen,
                    Icons.check_circle,
                  ),
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
              color: color.withOpacity(0.2),
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
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ComplaintsController controller) {
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
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari judul, penghuni, atau kamar...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: controller.clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
            // Tenant filter dropdown
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list, color: Colors.grey.shade600),
              onSelected: (value) {
                controller.setTenantFilter(value);
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(value: '', child: Text('Semua Penghuni')),
                  ...controller.tenants.map((tenant) {
                    return PopupMenuItem(
                      value: tenant.id,
                      child: Text(tenant.name),
                    );
                  }),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ComplaintsController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chips
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.statusOptions.map((option) {
                  final isSelected =
                      controller.selectedStatus.value == option['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(option['label']!),
                      selected: isSelected,
                      onSelected: (_) {
                        controller.setStatusFilter(option['value']!);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: _getStatusColor(option['value']!),
                      checkmarkColor: Colors.black87,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade600,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? _getStatusColor(option['value']!)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Category chips
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.categoryOptions.map((option) {
                  final isSelected =
                      controller.selectedCategory.value == option['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (option['value'] != 'all')
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                _getCategoryIcon(option['value']!),
                                size: 14,
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          Text(option['label']!),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        controller.setCategoryFilter(option['value']!);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.pastelBlue.withOpacity(0.3),
                      checkmarkColor: Colors.black87,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade600,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.pastelBlue
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(
    Complaint complaint,
    ComplaintsController controller,
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
          onTap: () {
            Get.toNamed(AppRoutes.ADMIN_COMPLAINT_DETAIL, arguments: complaint);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Status & Category
                Row(
                  children: [
                    _buildStatusBadge(complaint.status),
                    const SizedBox(width: 8),
                    _buildCategoryBadge(complaint.category),
                    const Spacer(),
                    Text(
                      complaint.timeSinceCreated,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  complaint.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Description preview
                Text(
                  complaint.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Divider(height: 24),

                // Footer: Tenant info & attachments
                Row(
                  children: [
                    // Tenant photo
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.pastelBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: complaint.tenantPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: complaint.tenantPhoto!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 18,
                              color: Colors.black45,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint.tenantName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Kamar ${complaint.roomNumber ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (complaint.hasAttachments)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pastelBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 14,
                              color: AppTheme.pastelBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${complaint.attachments.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.pastelBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Quick actions for new complaints
                if (complaint.isSubmitted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showUpdateStatusDialog(
                              complaint,
                              controller,
                              'in_progress',
                            );
                          },
                          icon: const Icon(Icons.engineering, size: 18),
                          label: const Text('Proses'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warmPeach,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showResolveDialog(complaint, controller);
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Selesaikan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.softGreen,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Quick action for in-progress
                if (complaint.isInProgress) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showResolveDialog(complaint, controller);
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Tandai Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.softGreen,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'submitted':
        color = AppTheme.softPink;
        label = 'Diajukan';
        icon = Icons.pending;
        break;
      case 'in_progress':
        color = AppTheme.warmPeach;
        label = 'Diproses';
        icon = Icons.engineering;
        break;
      case 'resolved':
        color = AppTheme.softGreen;
        label = 'Selesai';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 14,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            ComplaintCategory.getLabel(category),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ComplaintsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Gagal Memuat Data',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pastelBlue,
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ComplaintsController controller) {
    final isFiltered =
        controller.selectedStatus.value != 'all' ||
        controller.selectedCategory.value != 'all' ||
        controller.selectedTenantId.value.isNotEmpty ||
        controller.searchQuery.value.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off : Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'Tidak Ada Hasil' : 'Belum Ada Keluhan',
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
                : 'Keluhan dari penghuni akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Reset Filter'),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppTheme.softPink;
      case 'in_progress':
        return AppTheme.warmPeach;
      case 'resolved':
        return AppTheme.softGreen;
      default:
        return AppTheme.pastelBlue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'fasilitas':
        return Icons.build;
      case 'kebersihan':
        return Icons.cleaning_services;
      case 'keamanan':
        return Icons.security;
      case 'listrik':
        return Icons.electrical_services;
      case 'air':
        return Icons.water_drop;
      case 'lainnya':
        return Icons.help_outline;
      default:
        return Icons.report_problem;
    }
  }

  void _showUpdateStatusDialog(
    Complaint complaint,
    ComplaintsController controller,
    String newStatus,
  ) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          newStatus == 'in_progress' ? 'Proses Keluhan' : 'Update Status',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubah status keluhan "${complaint.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Tambahkan catatan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.updateStatus(
                complaint,
                newStatus,
                notes: notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmPeach,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Proses'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(
    Complaint complaint,
    ComplaintsController controller,
  ) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Selesaikan Keluhan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tandai keluhan "${complaint.title}" sebagai selesai?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan Penyelesaian',
                hintText: 'Jelaskan solusi atau tindakan yang diambil...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.updateStatus(
                complaint,
                'resolved',
                notes: notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.softGreen,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
  }
}
