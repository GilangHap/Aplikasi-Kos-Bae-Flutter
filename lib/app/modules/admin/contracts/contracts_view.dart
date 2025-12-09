// FILE: lib/app/modules/admin/contracts/contracts_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/contract_model.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'contracts_controller.dart';

/// Admin Contracts Management View
class AdminContractsView extends StatelessWidget {
  const AdminContractsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<ContractsController>()) {
      Get.put(ContractsController());
    }
    final controller = Get.find<ContractsController>();

    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          slivers: [
            // Premium Header
            SliverToBoxAdapter(child: _buildPremiumHeader(controller)),

            // Statistics Cards
            SliverToBoxAdapter(child: _buildStatisticsSection(controller)),

            // Search & Filter Bar
            SliverToBoxAdapter(child: _buildSearchBar(controller)),

            // Filter Chips
            SliverToBoxAdapter(child: _buildFilterChips(controller)),

            // Contracts List
            Obx(() {
              if (controller.isLoading.value && controller.contracts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                );
              }

              if (controller.errorMessage.value.isNotEmpty &&
                  controller.contracts.isEmpty) {
                return SliverFillRemaining(child: _buildErrorState(controller));
              }

              if (controller.filteredContracts.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(controller));
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final contract = controller.filteredContracts[index];
                    return _buildContractCard(contract, controller);
                  }, childCount: controller.filteredContracts.length),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildPremiumHeader(ContractsController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            AppTheme.lightBlue,
            const Color(0xFF8BC6C8),
          ],
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
      child: SafeArea(
        bottom: false,
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
              bottom: 20,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manajemen',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          'Kontrak',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${controller.statistics['total']} total kontrak',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(ContractsController controller) {
    return Obx(() {
      final stats = controller.statistics;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatCard(
                'Aktif',
                '${stats['aktif']}',
                const Color(0xFF4CAF50),
                const Color(0xFF81C784),
                Icons.check_circle_rounded,
              ),
              const SizedBox(width: 14),
              _buildStatCard(
                'Akan Habis',
                '${stats['akanHabis']}',
                const Color(0xFFFF9800),
                const Color(0xFFFFB74D),
                Icons.warning_rounded,
              ),
              const SizedBox(width: 14),
              _buildStatCard(
                'Berakhir',
                '${stats['berakhir']}',
                const Color(0xFFE91E63),
                const Color(0xFFF48FB1),
                Icons.cancel_rounded,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color startColor,
    Color endColor,
    IconData icon,
  ) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
                count,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
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

  Widget _buildSearchBar(ContractsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.charcoal,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama penghuni...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.charcoal.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: controller.onSearchChanged,
              ),
            ),
            Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGrey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.charcoal.withOpacity(0.6),
                    ),
                  ),
                  onPressed: controller.clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ContractsController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: controller.filterOptions.map((option) {
              final isSelected =
                  controller.selectedFilter.value == option['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => controller.setFilter(option['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.lightBlue,
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppTheme.mediumGrey,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.35),
                                blurRadius: 10,
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
                    child: Text(
                      option['label']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.charcoal.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(Contract contract, ContractsController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final result = await Get.toNamed(
              AppRoutes.ADMIN_CONTRACT_DETAIL,
              arguments: contract,
            );
            if (result == true) {
              controller.refreshData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with tenant info and status
                Row(
                  children: [
                    // Tenant avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.15),
                            AppTheme.cream.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: contract.tenantPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: contract.tenantPhoto!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Center(
                                  child: Text(
                                    contract.tenantName
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryBlue,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Center(
                                  child: Text(
                                    contract.tenantName
                                            ?.substring(0, 1)
                                            .toUpperCase() ??
                                        '?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryBlue,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                contract.tenantName
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    '?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract.tenantName ?? 'Unknown',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room_rounded,
                                size: 14,
                                color: AppTheme.charcoal.withOpacity(0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Kamar ${contract.roomNumber ?? '-'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.charcoal.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(contract.status),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppTheme.mediumGrey),
                ),

                // Contract details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today_rounded,
                        'Mulai',
                        contract.formattedStartDate,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.event_rounded,
                        'Berakhir',
                        contract.formattedEndDate,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.payments_rounded,
                        'Sewa/Bulan',
                        contract.formattedMonthlyRent,
                      ),
                    ),
                  ],
                ),

                // Expiry warning
                if (contract.status == 'akan_habis') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF9800).withOpacity(0.15),
                          const Color(0xFFFFB74D).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Kontrak berakhir dalam ${contract.daysUntilExpiry} hari',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Document indicator
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: contract.hasDocument
                            ? const Color(0xFFE74C3C).withOpacity(0.1)
                            : AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            contract.hasDocument
                                ? Icons.picture_as_pdf_rounded
                                : Icons.file_present_rounded,
                            size: 14,
                            color: contract.hasDocument
                                ? const Color(0xFFE74C3C)
                                : AppTheme.charcoal.withOpacity(0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contract.hasDocument
                                ? 'Dokumen tersedia'
                                : 'Belum ada dokumen',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: contract.hasDocument
                                  ? const Color(0xFFE74C3C)
                                  : AppTheme.charcoal.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${contract.durationMonths} bulan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.charcoal.withOpacity(0.6),
                        ),
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.charcoal.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.charcoal.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color startColor;
    Color endColor;
    String label;
    IconData icon;

    switch (status) {
      case 'aktif':
        startColor = const Color(0xFF4CAF50);
        endColor = const Color(0xFF81C784);
        label = 'Aktif';
        icon = Icons.check_circle_rounded;
        break;
      case 'akan_habis':
        startColor = const Color(0xFFFF9800);
        endColor = const Color(0xFFFFB74D);
        label = 'Akan Habis';
        icon = Icons.warning_rounded;
        break;
      case 'berakhir':
        startColor = const Color(0xFFE91E63);
        endColor = const Color(0xFFF48FB1);
        label = 'Berakhir';
        icon = Icons.cancel_rounded;
        break;
      default:
        startColor = AppTheme.primaryBlue;
        endColor = AppTheme.lightBlue;
        label = status;
        icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [startColor, endColor]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'contracts_fab',
        onPressed: () async {
          final result = await Get.toNamed(AppRoutes.ADMIN_CONTRACT_FORM);
          if (result == true && Get.isRegistered<ContractsController>()) {
            Get.find<ContractsController>().refreshData();
          }
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Buat Kontrak',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  Widget _buildErrorState(ContractsController controller) {
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
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFE74C3C),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.errorMessage.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
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
              onPressed: controller.refreshData,
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

  Widget _buildEmptyState(ContractsController controller) {
    final isFiltered =
        controller.selectedFilter.value != 'all' ||
        controller.searchQuery.value.isNotEmpty;

    return Center(
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
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.description_outlined,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isFiltered ? 'Tidak ada hasil' : 'Belum ada kontrak',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isFiltered
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Buat kontrak pertama untuk penghuni',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoal.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlue, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextButton(
                onPressed: controller.clearFilters,
                child: Text(
                  'Reset Filter',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
