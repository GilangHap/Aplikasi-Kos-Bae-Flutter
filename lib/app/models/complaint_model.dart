import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Complaint {
  final String id;
  final String tenantId;
  final String? roomId;
  final String title;
  final String description;
  final String
  category; // fasilitas, kebersihan, keamanan, listrik, air, lainnya
  final String status; // submitted, in_progress, resolved
  final String? priority; // low, medium, high
  final List<String> attachments; // photo/video URLs
  final String? adminNotes;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  // Joined data
  final String? tenantName;
  final String? tenantPhone;
  final String? tenantPhoto;
  final String? roomNumber;

  // Status history
  final List<ComplaintStatusHistory> statusHistory;

  Complaint({
    required this.id,
    required this.tenantId,
    this.roomId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    this.priority,
    this.attachments = const [],
    this.adminNotes,
    this.resolutionNotes,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.tenantName,
    this.tenantPhone,
    this.tenantPhoto,
    this.roomNumber,
    this.statusHistory = const [],
  });

  /// Create from Supabase JSON with joins
  factory Complaint.fromJson(Map<String, dynamic> json) {
    // Handle joined tenant data
    String? tenantName;
    String? tenantPhone;
    String? tenantPhoto;
    if (json['tenants'] != null && json['tenants'] is Map) {
      final tenantData = json['tenants'] as Map<String, dynamic>;
      tenantName = tenantData['name'] as String?;
      tenantPhone = tenantData['phone'] as String?;
      tenantPhoto = tenantData['photo_url'] as String?;
    }

    // Handle joined room data
    String? roomNumber;
    if (json['rooms'] != null && json['rooms'] is Map) {
      roomNumber = json['rooms']['room_number'] as String?;
    }

    // Parse attachments
    List<String> attachments = [];
    
    // Check 'media' column (JSONB)
    if (json['media'] != null) {
      if (json['media'] is List) {
        attachments.addAll(List<String>.from(json['media']));
      }
    }

    // Check 'attachments' column (Array)
    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        attachments.addAll(List<String>.from(json['attachments']));
      } else if (json['attachments'] is String) {
        // Handle JSON string if needed
      }
    }
    
    // Deduplicate
    attachments = attachments.toSet().toList();

    // Parse status history
    List<ComplaintStatusHistory> statusHistory = [];
    if (json['complaint_status_history'] != null &&
        json['complaint_status_history'] is List) {
      statusHistory = (json['complaint_status_history'] as List)
          .map(
            (h) => ComplaintStatusHistory.fromJson(h as Map<String, dynamic>),
          )
          .toList();
      // Sort by created_at descending
      statusHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Complaint(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      roomId: json['room_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'lainnya',
      status: json['status'] as String? ?? 'submitted',
      priority: json['priority'] as String?,
      attachments: attachments,
      adminNotes: json['admin_notes'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      tenantPhoto: tenantPhoto,
      roomNumber: roomNumber,
      statusHistory: statusHistory,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'room_id': roomId,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'attachments': attachments,
      'admin_notes': adminNotes,
      'resolution_notes': resolutionNotes,
    };
  }

  /// Copy with
  Complaint copyWith({
    String? id,
    String? tenantId,
    String? roomId,
    String? title,
    String? description,
    String? category,
    String? status,
    String? priority,
    List<String>? attachments,
    String? adminNotes,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? tenantName,
    String? tenantPhone,
    String? tenantPhoto,
    String? roomNumber,
    List<ComplaintStatusHistory>? statusHistory,
  }) {
    return Complaint(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      adminNotes: adminNotes ?? this.adminNotes,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      tenantName: tenantName ?? this.tenantName,
      tenantPhone: tenantPhone ?? this.tenantPhone,
      tenantPhoto: tenantPhoto ?? this.tenantPhoto,
      roomNumber: roomNumber ?? this.roomNumber,
      statusHistory: statusHistory ?? this.statusHistory,
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

  /// Get status label in Indonesian
  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Diajukan';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      default:
        return status;
    }
  }

  /// Get category label in Indonesian
  String get categoryLabel {
    switch (category) {
      case 'fasilitas':
        return 'Fasilitas';
      case 'kebersihan':
        return 'Kebersihan';
      case 'keamanan':
        return 'Keamanan';
      case 'listrik':
        return 'Listrik';
      case 'air':
        return 'Air';
      case 'lainnya':
        return 'Lainnya';
      default:
        return category;
    }
  }

  /// Get priority label
  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'Tinggi';
      case 'medium':
        return 'Sedang';
      case 'low':
        return 'Rendah';
      default:
        return 'Normal';
    }
  }

  /// Check if has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if is submitted
  bool get isSubmitted => status == 'submitted';

  /// Check if is in progress
  bool get isInProgress => status == 'in_progress';

  /// Check if is resolved
  bool get isResolved => status == 'resolved';
}

/// Status history for complaints
class ComplaintStatusHistory {
  final String id;
  final String complaintId;
  final String fromStatus;
  final String toStatus;
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;

  ComplaintStatusHistory({
    required this.id,
    required this.complaintId,
    required this.fromStatus,
    required this.toStatus,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });

  factory ComplaintStatusHistory.fromJson(Map<String, dynamic> json) {
    return ComplaintStatusHistory(
      id: json['id'] as String,
      complaintId: json['complaint_id'] as String,
      fromStatus: json['from_status'] as String,
      toStatus: json['to_status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  /// Get status label
  String getStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Diajukan';
      case 'in_progress':
        return 'Diproses';
      case 'resolved':
        return 'Selesai';
      default:
        return status;
    }
  }

  /// Get formatted date
  String get formattedDate {
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(createdAt);
  }
}

/// Complaint status constants
class ComplaintStatus {
  static const String submitted = 'submitted';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';

  static List<String> get all => [submitted, inProgress, resolved];

  static String getLabel(String status) {
    switch (status) {
      case submitted:
        return 'Diajukan';
      case inProgress:
        return 'Diproses';
      case resolved:
        return 'Selesai';
      default:
        return status;
    }
  }
}

/// Complaint category constants
class ComplaintCategory {
  static const String fasilitas = 'fasilitas';
  static const String kebersihan = 'kebersihan';
  static const String keamanan = 'keamanan';
  static const String listrik = 'listrik';
  static const String air = 'air';
  static const String lainnya = 'lainnya';

  static List<String> get all => [
    fasilitas,
    kebersihan,
    keamanan,
    listrik,
    air,
    lainnya,
  ];

  static String getLabel(String category) {
    switch (category) {
      case fasilitas:
        return 'Fasilitas';
      case kebersihan:
        return 'Kebersihan';
      case keamanan:
        return 'Keamanan';
      case listrik:
        return 'Listrik';
      case air:
        return 'Air';
      case lainnya:
        return 'Lainnya';
      default:
        return category;
    }
  }

  static IconData getIcon(String category) {
    switch (category) {
      case fasilitas:
        return Icons.build;
      case kebersihan:
        return Icons.cleaning_services;
      case keamanan:
        return Icons.security;
      case listrik:
        return Icons.electrical_services;
      case air:
        return Icons.water_drop;
      case lainnya:
        return Icons.help_outline;
      default:
        return Icons.report_problem;
    }
  }
}
