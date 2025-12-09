// FILE: lib/app/modules/admin/complaints/complaint_detail_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/complaint_model.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import 'complaints_controller.dart';

/// Complaint Detail Page
class ComplaintDetailView extends StatefulWidget {
  const ComplaintDetailView({super.key});

  @override
  State<ComplaintDetailView> createState() => _ComplaintDetailViewState();
}

class _ComplaintDetailViewState extends State<ComplaintDetailView> {
  late Complaint complaint;
  final _supabase = Get.find<SupabaseService>();
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    complaint = Get.arguments as Complaint;
    _refreshComplaintData();
  }

  Future<void> _refreshComplaintData() async {
    try {
      isLoading.value = true;
      final response = await _supabase.client
          .from('complaints')
          .select('''
            *,
            tenants(id, name, phone, photo_url),
            rooms(id, room_number),
            complaint_status_history(*)
          ''')
          .eq('id', complaint.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          complaint = Complaint.fromJson(response as Map<String, dynamic>);
        });
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildTenantInfoCard(),
                const SizedBox(height: 16),
                _buildDescriptionCard(),
                const SizedBox(height: 16),
                if (complaint.hasAttachments) ...[
                  _buildAttachmentsCard(),
                  const SizedBox(height: 16),
                ],
                _buildStatusHistoryCard(),
                const SizedBox(height: 16),
                _buildAdminNotesCard(),
                if (complaint.isResolved &&
                    complaint.resolutionNotes != null) ...[
                  const SizedBox(height: 16),
                  _buildResolutionCard(),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: !complaint.isResolved ? _buildActionBar() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _getStatusColor(complaint.status),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getStatusColor(complaint.status),
                _getStatusColor(complaint.status).withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(complaint.category),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.categoryLabel,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              complaint.statusLabel,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
      ),
    );
  }

  Widget _buildStatusCard() {
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
          Text(
            complaint.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoBadge(Icons.access_time, complaint.formattedDate),
              const SizedBox(width: 12),
              _buildInfoBadge(
                _getCategoryIcon(complaint.category),
                complaint.categoryLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantInfoCard() {
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.pastelBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: complaint.tenantPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: complaint.tenantPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Icon(Icons.person, color: Colors.black45),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.black45),
                    ),
                  )
                : const Icon(Icons.person, color: Colors.black45, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dilaporkan oleh',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  complaint.tenantName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kamar ${complaint.roomNumber ?? '-'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (complaint.tenantPhone != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.phone, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        complaint.tenantPhone!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Get.toNamed(
                AppRoutes.ADMIN_TENANT_DETAIL,
                arguments: {'tenantId': complaint.tenantId},
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.pastelBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: AppTheme.pastelBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
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
                  color: AppTheme.pastelBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description,
                  color: AppTheme.pastelBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Deskripsi Masalah',
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
            complaint.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
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
                  color: AppTheme.warmPeach.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_file,
                  color: AppTheme.warmPeach,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Lampiran (${complaint.attachments.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: complaint.attachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final url = complaint.attachments[index];
                return GestureDetector(
                  onTap: () => _showFullImage(url),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistoryCard() {
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
                  color: AppTheme.softGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, color: AppTheme.softGreen, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Riwayat Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (complaint.statusHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Belum ada perubahan status',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...complaint.statusHistory.map((history) {
              return _buildHistoryItem(history);
            }),
          // Initial submission
          _buildHistoryItemSimple(
            'Keluhan diajukan',
            complaint.formattedCreatedAt,
            Icons.add_circle,
            AppTheme.softPink,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ComplaintStatusHistory history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(history.toStatus).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(history.toStatus),
              size: 18,
              color: _getStatusColor(history.toStatus),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${history.getStatusLabel(history.fromStatus)} → ${history.getStatusLabel(history.toStatus)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  history.formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (history.notes != null && history.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    history.notes!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItemSimple(
    String title,
    String date,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotesCard() {
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.note_alt,
                  color: Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Catatan Admin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showEditNotesDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              complaint.adminNotes?.isNotEmpty == true
                  ? complaint.adminNotes!
                  : 'Belum ada catatan',
              style: TextStyle(
                fontSize: 14,
                color: complaint.adminNotes?.isNotEmpty == true
                    ? Colors.grey.shade700
                    : Colors.grey.shade400,
                fontStyle: complaint.adminNotes?.isNotEmpty == true
                    ? FontStyle.normal
                    : FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.softGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.softGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Catatan Penyelesaian',
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
            complaint.resolutionNotes!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          if (complaint.resolvedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Diselesaikan pada: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(complaint.resolvedAt!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (complaint.isSubmitted) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('in_progress'),
                  icon: const Icon(Icons.engineering),
                  label: const Text('Proses'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warmPeach,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: complaint.isSubmitted ? 1 : 2,
              child: ElevatedButton.icon(
                onPressed: _showResolveDialog,
                icon: const Icon(Icons.check_circle),
                label: const Text('Selesaikan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.softGreen,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.pending;
      case 'in_progress':
        return Icons.engineering;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
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

  void _showFullImage(String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNotesDialog() {
    final controller = TextEditingController(text: complaint.adminNotes);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Catatan Admin'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _updateAdminNotes(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pastelBlue,
              foregroundColor: Colors.black87,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAdminNotes(String notes) async {
    try {
      await _supabase.client
          .from('complaints')
          .update({
            'admin_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', complaint.id);

      await _refreshComplaintData();

      if (Get.isRegistered<ComplaintsController>()) {
        Get.find<ComplaintsController>().refreshData();
      }

      Get.snackbar(
        'Sukses',
        'Catatan berhasil disimpan',
        backgroundColor: AppTheme.softGreen,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal menyimpan catatan',
        backgroundColor: AppTheme.softPink,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _updateStatus(String newStatus, {String? notes}) async {
    try {
      final oldStatus = complaint.status;

      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == 'resolved') {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
        updateData['resolved_by'] = _supabase.auth.currentUser?.id;
        if (notes != null && notes.isNotEmpty) {
          updateData['resolution_notes'] = notes;
        }
      }

      await _supabase.client
          .from('complaints')
          .update(updateData)
          .eq('id', complaint.id);

      await _supabase.client.from('complaint_status_history').insert({
        'complaint_id': complaint.id,
        'from_status': oldStatus,
        'to_status': newStatus,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': _supabase.auth.currentUser?.id,
      });

      await _refreshComplaintData();

      if (Get.isRegistered<ComplaintsController>()) {
        Get.find<ComplaintsController>().refreshData();
      }

      Get.snackbar(
        'Sukses',
        'Status berhasil diupdate',
        backgroundColor: AppTheme.softGreen,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal mengupdate status',
        backgroundColor: AppTheme.softPink,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showResolveDialog() {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Selesaikan Keluhan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tandai keluhan ini sebagai selesai?'),
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
              await _updateStatus(
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
