import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/tenant_model.dart';
import '../../../theme/app_theme.dart';
import 'tenants_controller.dart';

/// Tenant Management View
class TenantsView extends GetView<TenantsController> {
  const TenantsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
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
          color: AppTheme.primaryBlue,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildPremiumHeader()),

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

  /// Header with gradient
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manajemen Penghuni',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelola data penghuni kos Anda',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Statistics cards
  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // Header with total tenants and sort button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  '${controller.statistics['total'] ?? 0} Penghuni Terdaftar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoal.withOpacity(0.7),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showSortBottomSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Urutkan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Stats cards - horizontal scroll
          SizedBox(
            height: 120,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard(
                    'Aktif',
                    (controller.statistics['active'] ?? 0).toString(),
                    [const Color(0xFF4CAF50), const Color(0xFF81C784)],
                    Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'Keluar',
                    (controller.statistics['left'] ?? 0).toString(),
                    [const Color(0xFFE91E63), const Color(0xFFF06292)],
                    Icons.exit_to_app_rounded,
                  ),
                  const SizedBox(width: 14),
                  _buildStatCard(
                    'Total',
                    (controller.statistics['total'] ?? 0).toString(),
                    [AppTheme.primaryBlue, AppTheme.lightBlue],
                    Icons.people_rounded,
                  ),
                ],
              ),
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
    List<Color> gradientColors,
    IconData icon,
  ) {
    return Container(
      width: 115,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Filter & Search Bar
  Widget _buildFilterSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search field with premium styling
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.charcoal.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              onChanged: controller.onSearchChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal,
              ),
              decoration: InputDecoration(
                hintText: 'Cari penghuni...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: AppTheme.charcoal.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryBlue,
                    size: 22,
                  ),
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.mediumGrey,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTheme.charcoal.withOpacity(0.6),
                              size: 16,
                            ),
                          ),
                          onPressed: controller.clearSearch,
                        )
                      : const SizedBox.shrink(),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter chips with premium styling
          SizedBox(
            height: 44,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'Semua', Icons.apps_rounded),
                  const SizedBox(width: 10),
                  _buildFilterChip(
                    'aktif',
                    'Aktif',
                    Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 10),
                  _buildFilterChip(
                    'keluar',
                    'Keluar',
                    Icons.exit_to_app_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = controller.selectedStatus.value == value;

    return GestureDetector(
      onTap: () => controller.setStatusFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.mediumGrey,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : AppTheme.charcoal.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : AppTheme.charcoal.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tenant card with premium styling
  Widget _buildTenantCard(Tenant tenant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.charcoal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(tenant),
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            // Photo Section with gradient overlay
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: SizedBox(
                width: 120,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    tenant.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: tenant.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                _buildPhotoPlaceholder(tenant),
                            errorWidget: (context, url, error) =>
                                _buildPhotoPlaceholder(tenant),
                          )
                        : _buildPhotoPlaceholder(tenant),
                    // Subtle gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.deepBlue.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    _buildStatusBadge(tenant.status),
                    const SizedBox(height: 10),

                    // Name
                    Text(
                      tenant.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Phone
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.cream.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tenant.phone,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.charcoal.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Room info
                    if (tenant.roomNumber != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.door_front_door_rounded,
                              size: 14,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kamar ${tenant.roomNumber}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),

                    // Contract start date (check-in)
                    if (tenant.contractStartDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppTheme.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(tenant.contractStartDate!),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoal.withOpacity(0.6),
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
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  _buildActionButton(
                    Icons.edit_rounded,
                    AppTheme.primaryBlue,
                    () => _navigateToForm(tenant),
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    Icons.delete_rounded,
                    const Color(0xFFE74C3C),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.2),
            AppTheme.cream.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Text(
          tenant.initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlue,
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
        bgColor = const Color(0xFF4CAF50).withOpacity(0.15);
        textColor = const Color(0xFF2E7D32);
        label = 'Aktif';
        icon = Icons.check_circle_rounded;
        break;
      case 'keluar':
        bgColor = const Color(0xFFE91E63).withOpacity(0.15);
        textColor = const Color(0xFFC2185B);
        label = 'Keluar';
        icon = Icons.exit_to_app_rounded;
        break;
      default:
        bgColor = AppTheme.mediumGrey;
        textColor = AppTheme.charcoal.withOpacity(0.7);
        label = status;
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  /// Loading shimmer
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.mediumGrey,
      highlightColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 18),
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.cream.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_rounded,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Belum Ada Penghuni',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tambahkan penghuni pertama Anda\ndengan menekan tombol + di bawah',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal.withOpacity(0.6),
                height: 1.6,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: const Color(0xFFE74C3C),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            controller.errorMessage.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: controller.fetchTenants,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Coba Lagi',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
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
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.deepBlue],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'tenants_fab',
        onPressed: () => _navigateToForm(null),
        icon: const Icon(
          Icons.person_add_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: Text(
          'Tambah Penghuni',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGrey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Urutkan Berdasarkan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => Column(
                children: [
                  _buildSortOption(
                    'name',
                    'Nama (A-Z)',
                    Icons.sort_by_alpha_rounded,
                  ),
                  _buildSortOption(
                    'created_at',
                    'Terbaru',
                    Icons.access_time_rounded,
                  ),
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

    return GestureDetector(
      onTap: () {
        controller.setSortBy(value);
        Get.back();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.1),
                    AppTheme.lightBlue.withOpacity(0.05),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.softGrey,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.15)
                    : AppTheme.mediumGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.charcoal.withOpacity(0.5),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.charcoal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Tenant tenant) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Hapus Penghuni?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal,
              ),
            ),
          ],
        ),
        content: Text(
          'Anda akan menghapus data penghuni "${tenant.name}". Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.charcoal.withOpacity(0.7),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.charcoal.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Get.back();
                final success = await controller.deleteTenant(tenant);
                if (success) {
                  Get.snackbar(
                    'Berhasil',
                    'Penghuni berhasil dihapus',
                    backgroundColor: const Color(0xFF4CAF50).withOpacity(0.9),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    borderRadius: 12,
                    margin: const EdgeInsets.all(16),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
