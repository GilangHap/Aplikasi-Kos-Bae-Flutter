class Room {
  final String id;
  final String roomNumber;
  final double price;
  final String status; // kosong, terisi, maintenance
  final List<String> photos;
  final List<String> facilities;
  final String description;
  final String? currentTenantName;
  final String? contractId; // Current active contract
  final DateTime createdAt;
  final DateTime? updatedAt;

  Room({
    required this.id,
    required this.roomNumber,
    required this.price,
    required this.status,
    required this.photos,
    required this.facilities,
    required this.description,
    this.currentTenantName,
    this.contractId,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Room from Supabase JSON
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      roomNumber: json['room_number'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      facilities: (json['facilities'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String? ?? '',
      currentTenantName: json['current_tenant_name'] as String?,
      contractId: json['contract_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Room to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'room_number': roomNumber,
      'price': price,
      'status': status,
      'photos': photos,
      'facilities': facilities,
      'description': description,
    };
  }

  /// Copy with method for updates
  Room copyWith({
    String? id,
    String? roomNumber,
    double? price,
    String? status,
    List<String>? photos,
    List<String>? facilities,
    String? description,
    String? currentTenantName,
    String? contractId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      price: price ?? this.price,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      facilities: facilities ?? this.facilities,
      description: description ?? this.description,
      currentTenantName: currentTenantName ?? this.currentTenantName,
      contractId: contractId ?? this.contractId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Status helpers
  bool get isEmpty => status == 'kosong';
  bool get isOccupied => status == 'terisi';
  bool get isUnderMaintenance => status == 'maintenance';

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'kosong':
        return '#B9F3CC'; // softGreen
      case 'terisi':
        return '#F7C4D4'; // softPink
      case 'maintenance':
        return '#F7F5C6'; // lightYellow
      default:
        return '#A9C9FF'; // pastelBlue
    }
  }

  String get statusLabel {
    switch (status) {
      case 'kosong':
        return 'Kosong';
      case 'terisi':
        return 'Terisi';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Unknown';
    }
  }

  /// Get formatted price in Indonesian Rupiah
  String get formattedPrice {
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}

/// Room status enum
class RoomStatus {
  static const String empty = 'kosong';
  static const String occupied = 'terisi';
  static const String maintenance = 'maintenance';

  static List<String> get all => [empty, occupied, maintenance];

  static String getLabel(String status) {
    switch (status) {
      case empty:
        return 'Kosong';
      case occupied:
        return 'Terisi';
      case maintenance:
        return 'Maintenance';
      default:
        return status;
    }
  }
}
