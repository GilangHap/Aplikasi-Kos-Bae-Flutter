// FILE: lib/app/modules/admin/contracts/contracts_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        color: AppTheme.pastelBlue,
        child: CustomScrollView(
          slivers: [
            // Statistics Cards
            SliverToBoxAdapter(
              child: _buildStatisticsSection(controller),
            ),

            // Search & Filter Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(controller),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: _buildFilterChips(controller),
            ),

            // Contracts List
            Obx(() {
              if (controller.isLoading.value && controller.contracts.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.errorMessage.value.isNotEmpty &&
                  controller.contracts.isEmpty) {
                return SliverFillRemaining(
                  child: _buildErrorState(controller),
                );
              }

              if (controller.filteredContracts.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(controller),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final contract = controller.filteredContracts[index];
                      return _buildContractCard(contract, controller);
                    },
                    childCount: controller.filteredContracts.length,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildStatisticsSection(ContractsController controller) {
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
                      'Manajemen Kontrak',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats['total']} total kontrak',
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
                    Icons.description,
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
                  'Aktif',
                  '${stats['aktif']}',
                  AppTheme.softGreen,
                  Icons.check_circle,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Akan Habis',
                  '${stats['akanHabis']}',
                  AppTheme.warmPeach,
                  Icons.warning,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Berakhir',
                  '${stats['berakhir']}',
                  AppTheme.softPink,
                  Icons.cancel,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
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

  Widget _buildSearchBar(ContractsController controller) {
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
                  hintText: 'Cari berdasarkan nama penghuni...',
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

  Widget _buildFilterChips(ContractsController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Obx(() => SingleChildScrollView(
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
                    onSelected: (_) =>
                        controller.setFilter(option['value']!),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.pastelBlue.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.pastelBlue : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          )),
    );
  }

  Widget _buildContractCard(Contract contract, ContractsController controller) {
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
              AppRoutes.ADMIN_CONTRACT_DETAIL,
              arguments: contract,
            );
            if (result == true) {
              controller.refreshData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with tenant info and status
                Row(
                  children: [
                    // Tenant avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.pastelBlue.withOpacity(0.2),
                      backgroundImage: contract.tenantPhoto != null
                          ? CachedNetworkImageProvider(contract.tenantPhoto!)
                          : null,
                      child: contract.tenantPhoto == null
                          ? Text(
                              contract.tenantName?.substring(0, 1).toUpperCase() ?? '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.pastelBlue,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract.tenantName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.meeting_room,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Kamar ${contract.roomNumber ?? '-'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
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

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Contract details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        'Mulai',
                        contract.formattedStartDate,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.event,
                        'Berakhir',
                        contract.formattedEndDate,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.payments,
                        'Sewa/Bulan',
                        contract.formattedMonthlyRent,
                      ),
                    ),
                  ],
                ),

                // Expiry warning
                if (contract.status == 'akan_habis') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.warmPeach.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Kontrak berakhir dalam ${contract.daysUntilExpiry} hari',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Document indicator
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      contract.hasDocument ? Icons.picture_as_pdf : Icons.file_present,
                      size: 16,
                      color: contract.hasDocument
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      contract.hasDocument
                          ? 'Dokumen tersedia'
                          : 'Belum ada dokumen',
                      style: TextStyle(
                        fontSize: 12,
                        color: contract.hasDocument
                            ? Colors.red.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${contract.durationMonths} bulan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
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
            Icon(icon, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'aktif':
        bgColor = AppTheme.softGreen.withOpacity(0.2);
        textColor = Colors.green.shade700;
        label = 'Aktif';
        icon = Icons.check_circle;
        break;
      case 'akan_habis':
        bgColor = AppTheme.warmPeach.withOpacity(0.2);
        textColor = Colors.orange.shade700;
        label = 'Akan Habis';
        icon = Icons.warning;
        break;
      case 'berakhir':
        bgColor = AppTheme.softPink.withOpacity(0.2);
        textColor = Colors.red.shade400;
        label = 'Berakhir';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
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
        heroTag: 'contracts_fab',
        onPressed: () async {
          final result = await Get.toNamed(AppRoutes.ADMIN_CONTRACT_FORM);
          if (result == true && Get.isRegistered<ContractsController>()) {
            Get.find<ContractsController>().refreshData();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Buat Kontrak',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildEmptyState(ContractsController controller) {
    final isFiltered = controller.selectedFilter.value != 'all' ||
        controller.searchQuery.value.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'Tidak ada hasil' : 'Belum ada kontrak',
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
                : 'Buat kontrak pertama untuk penghuni',
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
}
