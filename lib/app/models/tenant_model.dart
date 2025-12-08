// FILE: lib/app/models/tenant_model.dart
/// Tenant model for Kos Bae boarding house management
class Tenant {
  final String id;
  final String name;
  final String phone;
  final String? nik;
  final String? address;
  final String? photoUrl;
  final String? roomNumber; // From joined contract → room data
  final String? contractId; // Current active contract
  final DateTime? contractStartDate; // From joined contract data
  final DateTime? contractEndDate; // From joined contract data
  final String status; // aktif, keluar
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId;

  Tenant({
    required this.id,
    required this.name,
    required this.phone,
    this.nik,
    this.address,
    this.photoUrl,
    this.roomNumber,
    this.contractId,
    this.contractStartDate,
    this.contractEndDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.userId,
  });

  /// Create Tenant from Supabase JSON
  factory Tenant.fromJson(Map<String, dynamic> json) {
    // Handle joined contract data
    String? roomNumber;
    DateTime? contractStartDate;
    DateTime? contractEndDate;
    
    if (json['contracts'] != null && json['contracts'] is Map) {
      final contract = json['contracts'] as Map<String, dynamic>;
      
      // Get dates from contract
      if (contract['start_date'] != null) {
        contractStartDate = DateTime.parse(contract['start_date'] as String);
      }
      if (contract['end_date'] != null) {
        contractEndDate = DateTime.parse(contract['end_date'] as String);
      }
      
      // Get room number from contract → room join
      if (contract['rooms'] != null && contract['rooms'] is Map) {
        roomNumber = contract['rooms']['room_number'] as String?;
      }
    }

    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      nik: json['nik'] as String?,
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
      roomNumber: roomNumber,
      contractId: json['contract_id'] as String?,
      contractStartDate: contractStartDate,
      contractEndDate: contractEndDate,
      status: json['status'] as String? ?? 'aktif',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userId: json['user_id'] as String?,
    );
  }

  /// Convert Tenant to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'nik': nik,
      'address': address,
      'photo_url': photoUrl,
      'contract_id': contractId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_id': userId,
    };
  }

  /// Copy with method for updates
  Tenant copyWith({
    String? id,
    String? name,
    String? phone,
    String? nik,
    String? address,
    String? photoUrl,
    String? roomNumber,
    String? contractId,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nik: nik ?? this.nik,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      roomNumber: roomNumber ?? this.roomNumber,
      contractId: contractId ?? this.contractId,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  /// Status helpers
  bool get isActive => status == 'aktif';
  bool get hasLeft => status == 'keluar';
  bool get isInactive => status == 'nonaktif';

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'aktif':
        return '#B9F3CC'; // softGreen
      case 'nonaktif':
        return '#E2E8F0'; // slate200 (Grey)
      case 'keluar':
        return '#F7C4D4'; // softPink
      default:
        return '#A9C9FF'; // pastelBlue
    }
  }

  /// Get status label in Indonesian
  String get statusLabel {
    switch (status) {
      case 'aktif':
        return 'Aktif';
      case 'nonaktif':
        return 'Nonaktif';
      case 'keluar':
        return 'Keluar';
      default:
        return 'Unknown';
    }
  }

  /// Get initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// Tenant status enum
class TenantStatus {
  static const String active = 'aktif';
  static const String inactive = 'nonaktif';
  static const String left = 'keluar';

  static List<String> get all => [active, inactive, left];

  static String getLabel(String status) {
    switch (status) {
      case active:
        return 'Aktif';
      case inactive:
        return 'Nonaktif';
      case left:
        return 'Keluar';
      default:
        return status;
    }
  }
}
