import 'package:intl/intl.dart';

class Contract {
  final String id;
  final String tenantId;
  final String? roomId;
  final String? tenantName;
  final String? tenantPhone;
  final String? tenantPhoto;
  final String? roomNumber;
  final double monthlyRent;
  final DateTime startDate;
  final DateTime endDate;
  final String? documentUrl;
  final String status; // aktif, akan_habis, berakhir
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? parentContractId; // For renewal tracking

  Contract({
    required this.id,
    required this.tenantId,
    this.roomId,
    this.tenantName,
    this.tenantPhone,
    this.tenantPhoto,
    this.roomNumber,
    required this.monthlyRent,
    required this.startDate,
    required this.endDate,
    this.documentUrl,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.parentContractId,
  });

  /// Create Contract from Supabase JSON
  factory Contract.fromJson(Map<String, dynamic> json) {
    // Handle joined tenant data
    String? tenantName;
    String? tenantPhone;
    String? tenantPhoto;
    String? roomNumber;

    if (json['tenants'] != null && json['tenants'] is Map) {
      final tenant = json['tenants'] as Map<String, dynamic>;
      tenantName = tenant['name'] as String?;
      tenantPhone = tenant['phone'] as String?;
      tenantPhoto = tenant['photo_url'] as String?;
      
      // Get room number from nested rooms in tenant
      if (tenant['rooms'] != null && tenant['rooms'] is Map) {
        roomNumber = tenant['rooms']['room_number'] as String?;
      }
    }

    // Also check direct room data
    if (json['rooms'] != null && json['rooms'] is Map) {
      roomNumber ??= json['rooms']['room_number'] as String?;
    }

    return Contract(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      roomId: json['room_id'] as String?,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      tenantPhoto: tenantPhoto,
      roomNumber: roomNumber,
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      documentUrl: json['document_url'] as String?,
      status: json['status'] as String? ?? 'aktif',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      parentContractId: json['parent_contract_id'] as String?,
    );
  }

  /// Convert Contract to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'room_id': roomId,
      'monthly_rent': monthlyRent,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'document_url': documentUrl,
      'status': status,
      'notes': notes,
      'parent_contract_id': parentContractId,
    };
  }

  /// Copy with method for updates
  Contract copyWith({
    String? id,
    String? tenantId,
    String? roomId,
    String? tenantName,
    String? tenantPhone,
    String? tenantPhoto,
    String? roomNumber,
    double? monthlyRent,
    DateTime? startDate,
    DateTime? endDate,
    String? documentUrl,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? parentContractId,
  }) {
    return Contract(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      tenantName: tenantName ?? this.tenantName,
      tenantPhone: tenantPhone ?? this.tenantPhone,
      tenantPhoto: tenantPhoto ?? this.tenantPhoto,
      roomNumber: roomNumber ?? this.roomNumber,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      parentContractId: parentContractId ?? this.parentContractId,
    );
  }

  // ==================== HELPERS ====================

  /// Check if contract is active
  bool get isActive => status == 'aktif';

  /// Check if contract is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    return daysLeft <= 30 && daysLeft > 0 && status == 'aktif';
  }

  /// Check if contract has expired
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Check if contract has document
  bool get hasDocument => documentUrl != null && documentUrl!.isNotEmpty;

  /// Get contract duration in months
  int get durationMonths {
    return ((endDate.difference(startDate).inDays) / 30).round();
  }

  /// Get days until expiry
  int get daysUntilExpiry => endDate.difference(DateTime.now()).inDays;

  /// Get formatted start date
  String get formattedStartDate {
    return DateFormat('dd MMM yyyy', 'id_ID').format(startDate);
  }

  /// Get formatted end date
  String get formattedEndDate {
    return DateFormat('dd MMM yyyy', 'id_ID').format(endDate);
  }

  /// Get formatted date range
  String get dateRangeLabel {
    return '${formattedStartDate} - ${formattedEndDate}';
  }

  /// Get formatted monthly rent
  String get formattedMonthlyRent {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(monthlyRent);
  }

  /// Get total contract value
  double get totalValue => monthlyRent * durationMonths;

  /// Get formatted total value
  String get formattedTotalValue {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(totalValue);
  }

  /// Get status color hex
  String get statusColor {
    switch (status) {
      case 'aktif':
        return '#B9F3CC'; 
      case 'akan_habis':
        return '#FFD6A5'; 
      case 'berakhir':
        return '#F7C4D4'; 
      default:
        return '#A9C9FF'; 
    }
  }

  /// Get status label in Indonesian
  String get statusLabel {
    switch (status) {
      case 'aktif':
        return 'Aktif';
      case 'akan_habis':
        return 'Akan Habis';
      case 'berakhir':
        return 'Berakhir';
      default:
        return 'Unknown';
    }
  }

  /// Get calculated status based on dates
  String get calculatedStatus {
    final now = DateTime.now();
    if (now.isAfter(endDate)) {
      return 'berakhir';
    } else if (daysUntilExpiry <= 30) {
      return 'akan_habis';
    }
    return 'aktif';
  }

  /// Get time since created
  String get timeSinceCreated {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} bulan lalu';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit lalu';
    }
    return 'Baru saja';
  }
}

/// Contract status enum
class ContractStatus {
  static const String aktif = 'aktif';
  static const String akanHabis = 'akan_habis';
  static const String berakhir = 'berakhir';

  static List<String> get all => [aktif, akanHabis, berakhir];

  static String getLabel(String status) {
    switch (status) {
      case aktif:
        return 'Aktif';
      case akanHabis:
        return 'Akan Habis';
      case berakhir:
        return 'Berakhir';
      default:
        return status;
    }
  }
}
