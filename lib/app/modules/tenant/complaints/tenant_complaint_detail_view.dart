import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class TenantComplaintDetailView extends StatelessWidget {
  final Map<String, dynamic> complaint;

  const TenantComplaintDetailView({Key? key, required this.complaint}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] as String;
    final title = complaint['title'] ?? 'Tanpa Judul';
    final description = complaint['description'] ?? 'Tidak ada deskripsi';
    final createdAt = DateTime.parse(complaint['created_at']);
    final mediaList = complaint['media'] as List? ?? [];

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'resolved':
      case 'closed':
        statusColor = AppTheme.softGreen;
        statusLabel = 'Selesai';
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusLabel = 'Diproses';
        statusIcon = Icons.build;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Menunggu';
        statusIcon = Icons.access_time_filled;
    }

    final adminNotes = complaint['admin_notes'] as String?;
    final resolutionNotes = complaint['resolution_notes'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detail Keluhan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 8),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Admin Notes Section
            if (adminNotes != null && adminNotes.isNotEmpty) ...[
              _buildNoteCard(
                title: 'Tanggapan Admin',
                content: adminNotes,
                icon: Icons.admin_panel_settings_rounded,
                color: Colors.blue.shade600,
                backgroundColor: Colors.blue.shade50,
              ),
              const SizedBox(height: 20),
            ],

            // Resolution Notes Section
            if (resolutionNotes != null && resolutionNotes.isNotEmpty) ...[
              _buildNoteCard(
                title: 'Solusi Penyelesaian',
                content: resolutionNotes,
                icon: Icons.check_circle_rounded,
                color: AppTheme.softGreen,
                backgroundColor: const Color(0xFFE8F5E9), // Very light green
              ),
              const SizedBox(height: 20),
            ],

            // Photos Section
            if (mediaList.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Foto Bukti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: mediaList.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: mediaList[index].toString(),
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 200,
                            color: Colors.grey.shade100,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 200,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Timeline Section
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Riwayat Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTimelineItem(
                    title: 'Keluhan Dibuat',
                    date: createdAt,
                    isCompleted: true,
                    isFirst: true,
                    isLast: status == 'submitted',
                  ),
                  if (status == 'in_progress' || status == 'resolved' || status == 'closed')
                    _buildTimelineItem(
                      title: 'Sedang Diproses',
                      date: null, // TODO: Add updated_at if available
                      isCompleted: true,
                      isFirst: false,
                      isLast: status == 'in_progress',
                    ),
                  if (status == 'resolved' || status == 'closed')
                    _buildTimelineItem(
                      title: 'Selesai',
                      date: null,
                      isCompleted: true,
                      isFirst: false,
                      isLast: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    DateTime? date,
    required bool isCompleted,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 24,
                color: isCompleted ? AppTheme.pastelBlue : Colors.grey.shade200,
              ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.pastelBlue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppTheme.pastelBlue : Colors.grey.shade300,
                  width: 3,
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: AppTheme.pastelBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isCompleted ? AppTheme.pastelBlue : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
                    color: isCompleted ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
