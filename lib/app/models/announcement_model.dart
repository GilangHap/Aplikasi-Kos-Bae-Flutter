// FILE: lib/app/models/announcement_model.dart
import 'package:intl/intl.dart';

/// Announcement model for Kos Bae announcements
class Announcement {
  final String id;
  final String title;
  final String content;
  final List<String> attachments;
  final bool isRequired; // Wajib dibaca
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  // Read tracking
  final List<AnnouncementRead> readBy;
  final int totalReaders;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.attachments = const [],
    this.isRequired = false,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.readBy = const [],
    this.totalReaders = 0,
  });

  /// Create from Supabase JSON
  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Parse attachments
    List<String> attachments = [];
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        attachments = List<String>.from(json['attachments']);
      }
    }

    // Parse read by list
    List<AnnouncementRead> readBy = [];
    if (json['announcement_reads'] != null &&
        json['announcement_reads'] is List) {
      readBy = (json['announcement_reads'] as List)
          .map((r) => AnnouncementRead.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      attachments: attachments,
      isRequired: json['is_required'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      readBy: readBy,
      totalReaders: readBy.length,
    );
  }

  /// Convert to Supabase JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'attachments': attachments,
      'is_required': isRequired,
    };
  }

  /// Copy with
  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? attachments,
    bool? isRequired,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<AnnouncementRead>? readBy,
    int? totalReaders,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      readBy: readBy ?? this.readBy,
      totalReaders: totalReaders ?? this.totalReaders,
    );
  }

  // ==================== HELPERS ====================

  /// Get formatted created date
  String get formattedCreatedAt {
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(createdAt);
  }

  /// Get formatted date only
  String get formattedDate {
    return DateFormat('dd MMM yyyy', 'id_ID').format(createdAt);
  }

  /// Get time since created
  String get timeSinceCreated {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  /// Check if has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Get content preview (first 100 chars)
  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  /// Get read count display
  String get readCountDisplay {
    if (totalReaders == 0) return 'Belum ada yang membaca';
    return '$totalReaders penghuni sudah membaca';
  }
}

/// Announcement read tracking model
class AnnouncementRead {
  final String id;
  final String announcementId;
  final String tenantId;
  final DateTime readAt;

  // Joined data
  final String? tenantName;
  final String? tenantPhoto;
  final String? roomNumber;

  AnnouncementRead({
    required this.id,
    required this.announcementId,
    required this.tenantId,
    required this.readAt,
    this.tenantName,
    this.tenantPhoto,
    this.roomNumber,
  });

  factory AnnouncementRead.fromJson(Map<String, dynamic> json) {
    // Handle joined tenant data
    String? tenantName;
    String? tenantPhoto;
    String? roomNumber;

    if (json['tenants'] != null && json['tenants'] is Map) {
      final tenantData = json['tenants'] as Map<String, dynamic>;
      tenantName = tenantData['name'] as String?;
      tenantPhoto = tenantData['photo_url'] as String?;

      // Handle nested room data
      if (tenantData['rooms'] != null && tenantData['rooms'] is Map) {
        roomNumber = tenantData['rooms']['room_number'] as String?;
      }
    }

    return AnnouncementRead(
      id: json['id'] as String,
      announcementId: json['announcement_id'] as String,
      tenantId: json['tenant_id'] as String,
      readAt: DateTime.parse(json['read_at'] as String),
      tenantName: tenantName,
      tenantPhoto: tenantPhoto,
      roomNumber: roomNumber,
    );
  }

  /// Get formatted read date
  String get formattedReadAt {
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(readAt);
  }
}
