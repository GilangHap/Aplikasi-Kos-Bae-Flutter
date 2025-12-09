// FILE: lib/app/modules/admin/tenants/tenant_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../models/tenant_model.dart';
import '../../../models/contract_model.dart';
import '../../../services/supabase_service.dart';
import 'tenants_controller.dart';

/// Tenant Detail Page - Shows full biodata, room info, dates
class TenantDetailView extends StatefulWidget {
  const TenantDetailView({super.key});

  @override
  State<TenantDetailView> createState() => _TenantDetailViewState();
}

class _TenantDetailViewState extends State<TenantDetailView> {
  // Pastel Colors
  static const Color pastelBlue = Color(0xFFA9C9FF);
  static const Color softGreen = Color(0xFFB9F3CC);
  static const Color warmPeach = Color(0xFFFFD6A5);
  static const Color softPink = Color(0xFFF7C4D4);
  static const Color lightLavender = Color(0xFFE2CFEA);
  static const Color softGrey = Color(0xFFF7F8FC);
  static const Color darkText = Color(0xFF2D3748);
  static const Color grayText = Color(0xFF718096);

  Tenant? tenant;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTenant();
  }

  Future<void> _initTenant() async {
    final arg = Get.arguments;
    // If a Tenant object was passed, use it
    if (arg is Tenant) {
      tenant = arg;
      setState(() => isLoading = false);
      return;
    }

    // If a Map with tenantId or a raw tenantId string was passed, fetch tenant
    String? tenantId;
    if (arg is Map && arg['tenantId'] != null) {
      tenantId = arg['tenantId'] as String?;
    } else if (arg is String) {
      tenantId = arg;
    }

    if (tenantId != null) {
      try {
        final service = Get.find<SupabaseService>();
        final fetched = await service.getTenantById(tenantId);
        setState(() {
          tenant = fetched;
          isLoading = false;
        });
        return;
      } catch (e) {
        // ignore and show empty state
        print('❌ Failed to fetch tenant by id: $e');
      }
    }

    // No usable argument provided
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (tenant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Penghuni')),
        body: Center(child: Text('Data penghuni tidak ditemukan')),
      );
    }

    final t = tenant!;

    return Scaffold(
      backgroundColor: softGrey,
      body: CustomScrollView(
        slivers: [
          // App Bar with Photo
          _buildSliverAppBar(t),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  _buildQuickStats(t),
                  const SizedBox(height: 24),

                  // Personal Info Card
                  _buildInfoCard(
                    title: 'Informasi Pribadi',
                    icon: Icons.person_rounded,
                    color: pastelBlue,
                    children: [
                      _buildInfoRow(
                        Icons.person_outline_rounded,
                        'Nama Lengkap',
                        t.name,
                      ),
                      _buildInfoRow(
                        Icons.phone_rounded,
                        'No. Telepon',
                        t.phone,
                      ),
                      _buildInfoRow(Icons.badge_rounded, 'NIK', t.nik ?? '-'),
                      _buildInfoRow(
                        Icons.home_rounded,
                        'Alamat',
                        t.address ?? '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Active Contract Info Card (if has contract)
                  if (t.contractId != null) ...[
                    FutureBuilder(
                      future: _fetchContractInfo(t.contractId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final contract =
                              snapshot.data as Map<String, dynamic>;
                          return _buildContractInfoCard(contract);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Room & Stay Info Card
                  _buildInfoCard(
                    title: 'Informasi Hunian',
                    icon: Icons.door_sliding_rounded,
                    color: warmPeach,
                    children: [
                      _buildInfoRow(
                        Icons.meeting_room_rounded,
                        'Kamar',
                        t.roomNumber ?? 'Belum ditentukan',
                      ),
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        'Tanggal Masuk',
                        t.contractStartDate != null
                            ? DateFormat(
                                'EEEE, dd MMMM yyyy',
                                'id_ID',
                              ).format(t.contractStartDate!)
                            : '-',
                      ),
                      _buildInfoRow(
                        Icons.event_rounded,
                        'Tanggal Keluar',
                        t.contractEndDate != null
                            ? DateFormat(
                                'EEEE, dd MMMM yyyy',
                                'id_ID',
                              ).format(t.contractEndDate!)
                            : '-',
                      ),
                      _buildInfoRow(
                        Icons.timelapse_rounded,
                        'Durasi Tinggal',
                        _calculateDuration(
                          t.contractStartDate,
                          t.contractEndDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // System Info Card
                  _buildInfoCard(
                    title: 'Informasi Sistem',
                    icon: Icons.info_outline_rounded,
                    color: lightLavender,
                    children: [
                      _buildInfoRow(
                        Icons.add_circle_outline_rounded,
                        'Ditambahkan',
                        DateFormat('dd MMM yyyy, HH:mm').format(t.createdAt),
                      ),
                      if (t.updatedAt != null)
                        _buildInfoRow(
                          Icons.edit_rounded,
                          'Terakhir Diupdate',
                          DateFormat('dd MMM yyyy, HH:mm').format(t.updatedAt!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(t),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sliver App Bar with hero photo
  Widget _buildSliverAppBar(Tenant tenant) {
    final statusColor = _getStatusColor(tenant.status);

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: pastelBlue,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkText),
          onPressed: () => Get.back(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: darkText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: darkText, size: 20),
                    const SizedBox(width: 12),
                    const Text('Edit Penghuni'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Hapus Penghuni',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                Get.toNamed('/admin/tenants/form', arguments: tenant);
              } else if (value == 'delete') {
                _showDeleteConfirmation(tenant);
              }
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            tenant.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: tenant.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: pastelBlue.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildAvatarFallback(tenant),
                  )
                : _buildAvatarFallback(tenant),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Name and Status Badge
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tenant.statusLabel,
                      style: const TextStyle(
                        color: darkText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    tenant.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Room info
                  if (tenant.roomNumber != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.door_sliding_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kamar ${tenant.roomNumber}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(Tenant tenant) {
    return Container(
      color: pastelBlue,
      child: Center(
        child: Text(
          tenant.initials,
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  /// Quick stats row
  Widget _buildQuickStats(Tenant tenant) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatItem(
            icon: Icons.calendar_today_rounded,
            label: 'Tanggal Masuk',
            value: tenant.contractStartDate != null
                ? DateFormat('dd MMM yyyy').format(tenant.contractStartDate!)
                : '-',
            color: softGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatItem(
            icon: Icons.timelapse_rounded,
            label: 'Durasi',
            value: _calculateDuration(
              tenant.contractStartDate,
              tenant.contractEndDate,
            ),
            color: warmPeach,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatItem(
            icon: Icons.circle,
            label: 'Status',
            value: tenant.statusLabel,
            color: _getStatusColor(tenant.status),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: darkText, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: darkText,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: grayText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Info card builder
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: darkText, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: grayText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: grayText)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Action buttons at the bottom
  Widget _buildActionButtons(Tenant tenant) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(tenant),
            icon: const Icon(Icons.delete_rounded, color: Colors.red),
            label: const Text('Hapus', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () =>
                Get.toNamed('/admin/tenants/form', arguments: tenant),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Penghuni'),
            style: ElevatedButton.styleFrom(
              backgroundColor: pastelBlue,
              foregroundColor: darkText,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  /// Calculate duration helper
  String _calculateDuration(DateTime? checkIn, DateTime? checkOut) {
    if (checkIn == null) return '-';

    final end = checkOut ?? DateTime.now();
    final difference = end.difference(checkIn);

    final months = (difference.inDays / 30).floor();
    final days = difference.inDays % 30;

    if (months > 0) {
      return '$months bulan ${days > 0 ? '$days hari' : ''}';
    }
    return '$days hari';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aktif':
        return softGreen;
      case 'keluar':
        return softPink;
      default:
        return pastelBlue;
    }
  }

  /// Delete confirmation dialog
  void _showDeleteConfirmation(Tenant tenant) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Hapus Penghuni?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anda akan menghapus data penghuni:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softPink.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tenant.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(color: grayText, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: TextStyle(color: grayText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _deleteTenant(tenant);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Delete tenant
  Future<void> _deleteTenant(Tenant tenant) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: pastelBlue)),
        barrierDismissible: false,
      );

      final controller = Get.find<TenantsController>();
      final success = await controller.deleteTenant(tenant);

      Get.back(); // Close loading

      if (success) {
        Get.back(); // Go back to list
        Get.snackbar(
          'Berhasil',
          'Penghuni berhasil dihapus',
          backgroundColor: softGreen,
          colorText: darkText,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Gagal',
          controller.errorMessage.value,
          backgroundColor: softPink,
          colorText: darkText,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: softPink,
        colorText: darkText,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Fetch contract information
  Future<Map<String, dynamic>> _fetchContractInfo(String contractId) async {
    try {
      final service = Get.find<SupabaseService>();
      final response = await service.client
          .from('contracts')
          .select('*')
          .eq('id', contractId)
          .single();
      return response;
    } catch (e) {
      print('❌ Error fetching contract: $e');
      return {};
    }
  }

  /// Build contract info card
  Widget _buildContractInfoCard(Map<String, dynamic> contract) {
    if (contract.isEmpty) return const SizedBox.shrink();

    final startDate = DateTime.parse(contract['start_date']);
    final endDate = DateTime.parse(contract['end_date']);
    final monthlyRent = (contract['monthly_rent'] as num).toDouble();
    final status = contract['status'] as String;

    // Calculate status color
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'aktif':
        statusColor = softGreen;
        statusLabel = 'Aktif';
        break;
      case 'akan_habis':
        statusColor = warmPeach;
        statusLabel = 'Akan Habis';
        break;
      default:
        statusColor = softPink;
        statusLabel = 'Berakhir';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pastelBlue.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pastelBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: darkText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Kontrak Aktif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  'Periode Kontrak',
                  '${DateFormat('dd MMM yyyy', 'id_ID').format(startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(endDate)}',
                ),
                _buildInfoRow(
                  Icons.payments_rounded,
                  'Sewa per Bulan',
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(monthlyRent),
                ),
                const SizedBox(height: 8),
                // Link to contract detail
                InkWell(
                  onTap: () {
                    // Convert contract Map to Contract model for proper navigation
                    try {
                      final contractModel = Contract.fromJson(contract);
                      Get.toNamed(
                        '/admin/contracts/detail',
                        arguments: contractModel,
                      );
                    } catch (e) {
                      print('Error navigating to contract detail: $e');
                      Get.snackbar(
                        'Error',
                        'Gagal membuka detail kontrak',
                        backgroundColor: softPink,
                        colorText: darkText,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pastelBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pastelBlue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 16,
                          color: pastelBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lihat Detail Kontrak',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pastelBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
