// FILE: lib/app/modules/admin/tenants/tenants_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../models/tenant_model.dart';
import '../../../theme/app_theme.dart';
import 'tenants_controller.dart';

/// Modern Tenant Management View for Admin
/// Features: Search, Sort, Filter, Cards with photo/name/phone/room/status
class TenantsView extends GetView<TenantsController> {
  const TenantsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value && controller.tenants.isEmpty) {
          return _buildLoadingShimmer();
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.tenants.isEmpty) {
          return _buildErrorState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppTheme.pastelBlue,
          child: CustomScrollView(
            slivers: [
              // Statistics Cards
              SliverToBoxAdapter(child: _buildStatisticsCards()),

              // Filter & Search Bar
              SliverToBoxAdapter(child: _buildFilterSearchBar()),

              // Tenant List
              if (controller.filteredTenants.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final tenant = controller.filteredTenants[index];
                      return _buildTenantCard(tenant);
                    }, childCount: controller.filteredTenants.length),
                  ),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: _buildFAB(),
    );
  }

  /// Statistics cards
  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // Header with total tenants and sort button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  '${controller.statistics['total'] ?? 0} Penghuni Terdaftar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showSortBottomSheet(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 16, color: AppTheme.pastelBlue),
                      const SizedBox(width: 6),
                      Text(
                        'Urutkan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.pastelBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats cards
          Obx(
            () => Row(
              children: [
                _buildStatCard(
                  'Aktif',
                  (controller.statistics['active'] ?? 0).toString(),
                  const Color(0xFF4CAF50),
                  Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Keluar',
                  (controller.statistics['left'] ?? 0).toString(),
                  const Color(0xFFE91E63),
                  Icons.exit_to_app,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Total',
                  (controller.statistics['total'] ?? 0).toString(),
                  const Color(0xFF2196F3),
                  Icons.people,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Filter & Search Bar
  Widget _buildFilterSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search field
          Container(
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
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari penghuni...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: AppTheme.pastelBlue),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SizedBox(
            height: 40,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'Semua', Icons.apps),
                  const SizedBox(width: 8),
                  _buildFilterChip('aktif', 'Aktif', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildFilterChip('keluar', 'Keluar', Icons.exit_to_app),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = controller.selectedStatus.value == value;

    return InkWell(
      onTap: () => controller.setStatusFilter(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.selectedGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.pastelBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tenant card
  Widget _buildTenantCard(Tenant tenant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(tenant),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Photo Section
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 120,
                height: 140,
                child: tenant.photoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: tenant.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _buildPhotoPlaceholder(tenant),
                        errorWidget: (context, url, error) =>
                            _buildPhotoPlaceholder(tenant),
                      )
                    : _buildPhotoPlaceholder(tenant),
              ),
            ),

            // Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    _buildStatusBadge(tenant.status),
                    const SizedBox(height: 8),

                    // Name
                    Text(
                      tenant.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Phone
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tenant.phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Room info
                    if (tenant.roomNumber != null)
                      Row(
                        children: [
                          Icon(
                            Icons.door_sliding,
                            size: 14,
                            color: AppTheme.pastelBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kamar ${tenant.roomNumber}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.pastelBlue,
                            ),
                          ),
                        ],
                      ),

                    // Contract start date (check-in)
                    if (tenant.contractStartDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(tenant.contractStartDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  _buildActionButton(
                    Icons.edit,
                    const Color(0xFFA9C9FF),
                    () => _navigateToForm(tenant),
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    Icons.delete,
                    const Color(0xFFFF6B6B),
                    () => _showDeleteConfirmation(tenant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder(Tenant tenant) {
    return Container(
      color: AppTheme.pastelBlue.withOpacity(0.2),
      child: Center(
        child: Text(
          tenant.initials,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.pastelBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'aktif':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Aktif';
        icon = Icons.check_circle;
        break;
      case 'keluar':
        bgColor = const Color(0xFFFCE4EC);
        textColor = const Color(0xFFC2185B);
        label = 'Keluar';
        icon = Icons.exit_to_app;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  /// Loading shimmer
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
                Icons.people_outline,
                size: 64,
                color: AppTheme.pastelBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Penghuni',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan penghuni pertama Anda\ndengan menekan tombol + di bawah',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.fetchTenants,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pastelBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// FAB
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
        heroTag: 'tenants_fab', // Unique hero tag to prevent conflict
        onPressed: () => _navigateToForm(null),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Tambah Penghuni',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  void _showSortBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Urutkan Berdasarkan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  _buildSortOption('name', 'Nama (A-Z)', Icons.sort_by_alpha),
                  _buildSortOption('created_at', 'Terbaru', Icons.access_time),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = controller.sortBy.value == value;

    return InkWell(
      onTap: () {
        controller.setSortBy(value);
        Get.back();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.pastelBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.pastelBlue : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.pastelBlue : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.pastelBlue),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Tenant tenant) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Hapus Penghuni?'),
          ],
        ),
        content: Text(
          'Anda akan menghapus data penghuni "${tenant.name}". Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteTenant(tenant);
              if (success) {
                Get.snackbar(
                  'Berhasil',
                  'Penghuni berhasil dihapus',
                  backgroundColor: AppTheme.softGreen,
                  colorText: Colors.black87,
                );
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

  void _navigateToDetail(Tenant tenant) {
    Get.toNamed('/admin/tenants/detail', arguments: tenant);
  }

  void _navigateToForm(Tenant? tenant) {
    Get.toNamed('/admin/tenants/form', arguments: tenant);
  }
}

/// Alias for old class name compatibility
typedef AdminTenantsView = TenantsView;
