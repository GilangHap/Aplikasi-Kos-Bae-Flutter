// FILE: lib/app/modules/admin/rooms_management/rooms_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'rooms_controller.dart';
import '../../../widgets/room_card.dart';
import '../../../theme/app_theme.dart';

/// Main Rooms Management View dengan UI yang lebih menarik
class RoomsView extends GetView<RoomsController> {
  const RoomsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value && controller.rooms.isEmpty) {
          return _buildLoadingShimmer();
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.pastelBlue,
          child: CustomScrollView(
            slivers: [
              // Statistics Cards (scrollable)
              SliverToBoxAdapter(child: _buildStatisticsCards()),

              // Filter & Search Bar (scrollable)
              SliverToBoxAdapter(child: _buildFilterSearchBar()),

              // Room List
              if (controller.rooms.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final room = controller.rooms[index];
                      return _buildRoomCard(room);
                    }, childCount: controller.rooms.length),
                  ),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // Header with total rooms and sort button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => Text(
                  '${controller.totalRooms} Kamar Terdaftar',
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
                  'Kosong',
                  controller.emptyRooms.toString(),
                  const Color(0xFF4CAF50),
                  Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Terisi',
                  controller.occupiedRooms.toString(),
                  const Color(0xFFE91E63),
                  Icons.person,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Perbaikan',
                  controller.maintenanceRooms.toString(),
                  const Color(0xFFFF9800),
                  Icons.build,
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
              onChanged: controller.setSearch,
              decoration: InputDecoration(
                hintText: 'Cari kamar...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: AppTheme.pastelBlue),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400),
                          onPressed: () {
                            controller.setSearch('');
                          },
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
                  _buildFilterChip('kosong', 'Kosong', Icons.check_circle),
                  const SizedBox(width: 8),
                  _buildFilterChip('terisi', 'Terisi', Icons.person),
                  const SizedBox(width: 8),
                  _buildFilterChip('maintenance', 'Perbaikan', Icons.build),
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
    final isSelected = controller.filterStatus.value == value;

    return InkWell(
      onTap: () => controller.setFilter(value),
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

  Widget _buildRoomCard(room) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
        onTap: () => controller.openDetail(room),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: room.photos.isNotEmpty
                      ? Image.network(
                          room.photos.first,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),

                // Status Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildStatusBadge(room.status),
                ),

                // Photo count
                if (room.photos.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room.photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kamar ${room.roomNumber}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(room.price),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.pastelBlue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action buttons
                      Row(
                        children: [
                          _buildActionButton(
                            Icons.edit,
                            const Color(0xFFA9C9FF),
                            () => controller.openEditRoom(room),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            Icons.delete,
                            const Color(0xFFFF6B6B),
                            () => controller.deleteRoom(room),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (room.currentTenantName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7C4D4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFFE91E63),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            room.currentTenantName!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (room.facilities.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: room.facilities
                          .take(4)
                          .map<Widget>(
                            (f) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade100],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Tidak ada foto', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'kosong':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Kosong';
        icon = Icons.check_circle;
        break;
      case 'terisi':
        bgColor = const Color(0xFFFCE4EC);
        textColor = const Color(0xFFC2185B);
        label = 'Terisi';
        icon = Icons.person;
        break;
      case 'maintenance':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        label = 'Perbaikan';
        icon = Icons.build;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20, width: 120, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 16, width: 100, color: Colors.white),
                    const SizedBox(height: 12),
                    Container(height: 24, width: 200, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                Icons.meeting_room_outlined,
                size: 64,
                color: AppTheme.pastelBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Kamar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan kamar pertama Anda\ndengan menekan tombol + di bawah',
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
        heroTag: 'rooms_fab', // Unique hero tag to prevent conflict
        onPressed: controller.openAddRoom,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Kamar',
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
                  _buildSortOption('room_number', 'Nomor Kamar', Icons.tag),
                  _buildSortOption('price', 'Harga', Icons.attach_money),
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
        controller.setSort(value);
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
}
