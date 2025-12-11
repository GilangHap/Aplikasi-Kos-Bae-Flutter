// FILE: lib/app/models/bill_model.dart
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../services/app_settings_service.dart';

/// Helper class to access AppSettingsService from Bill model
class _AppSettingsServiceHelper {
  static AppSettingsService? getService() {
    if (Get.isRegistered<AppSettingsService>()) {
      return Get.find<AppSettingsService>();
    }
    return null;
  }
}
/// Bill model for Kos Bae boarding house management
class Bill {
  final String id;
  final String tenantId;
  final String? roomId;
  final String?
  contractId; // Reference to the contract that generated this bill
  final String? tenantName; // From joined data
  final String? roomNumber; // From joined data
  final double amount;
  final String type; // sewa, listrik, air, deposit, denda, lainnya
  final String status; // pending, verified, paid, overdue
  final DateTime dueDate;
  final DateTime billingPeriodStart;
  final DateTime billingPeriodEnd;
  final String? notes;
  final String? adminNotes;
  final List<Payment> payments;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  Bill({
    required this.id,
    required this.tenantId,
    this.roomId,
    this.contractId,
    this.tenantName,
    this.roomNumber,
    required this.amount,
    required this.type,
    required this.status,
    required this.dueDate,
    required this.billingPeriodStart,
    required this.billingPeriodEnd,
    this.notes,
    this.adminNotes,
    this.payments = const [],
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Create Bill from Supabase JSON
  factory Bill.fromJson(Map<String, dynamic> json) {
    // Handle joined tenant data
    String? tenantName;
    if (json['tenants'] != null && json['tenants'] is Map) {
      tenantName = json['tenants']['name'] as String?;
    }

    // Handle joined room data
    String? roomNumber;
    if (json['rooms'] != null && json['rooms'] is Map) {
      roomNumber = json['rooms']['room_number'] as String?;
    }

    // Parse payments
    List<Payment> payments = [];
    if (json['payments'] != null && json['payments'] is List) {
      payments = (json['payments'] as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return Bill(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      roomId: json['room_id'] as String?,
      contractId: json['contract_id'] as String?,
      tenantName: tenantName,
      roomNumber: roomNumber,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String? ?? 'sewa',
      status: json['status'] as String? ?? 'pending',
      dueDate: DateTime.parse(json['due_date'] as String),
      billingPeriodStart: DateTime.parse(
        json['billing_period_start'] as String,
      ),
      billingPeriodEnd: DateTime.parse(json['billing_period_end'] as String),
      notes: json['notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      payments: payments,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  /// Convert Bill to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'room_id': roomId,
      'contract_id': contractId,
      'amount': amount,
      'type': type,
      'status': status,
      'due_date': dueDate.toIso8601String().split('T').first,
      'billing_period_start': billingPeriodStart
          .toIso8601String()
          .split('T')
          .first,
      'billing_period_end': billingPeriodEnd.toIso8601String().split('T').first,
      'notes': notes,
      'admin_notes': adminNotes,
    };
  }

  /// Copy with method for updates
  Bill copyWith({
    String? id,
    String? tenantId,
    String? roomId,
    String? contractId,
    String? tenantName,
    String? roomNumber,
    double? amount,
    String? type,
    String? status,
    DateTime? dueDate,
    DateTime? billingPeriodStart,
    DateTime? billingPeriodEnd,
    String? notes,
    String? adminNotes,
    List<Payment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Bill(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      roomId: roomId ?? this.roomId,
      contractId: contractId ?? this.contractId,
      tenantName: tenantName ?? this.tenantName,
      roomNumber: roomNumber ?? this.roomNumber,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      billingPeriodStart: billingPeriodStart ?? this.billingPeriodStart,
      billingPeriodEnd: billingPeriodEnd ?? this.billingPeriodEnd,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ==================== HELPERS ====================

  /// Get total paid amount
  double get totalPaid {
    return payments
        .where((p) => p.status == 'verified')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Get remaining amount
  double get remainingAmount => amount - totalPaid;

  /// Check if fully paid
  bool get isFullyPaid => remainingAmount <= 0;

  /// Check if overdue
  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != 'paid';

  /// Get days until due
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  
  /// Calculate late fee based on app settings
  /// This uses the AppSettingsService to get current late fee settings
  double calculateLateFee() {
    try {
      if (status == 'paid') return 0;
      
      // Get settings from service
      int gracePeriodDays = 3;
      int lateFeePercentage = 5;
      bool enableLateFee = true;
      
      // Try to get from AppSettingsService if available
      try {
        // Use dynamic import to avoid circular dependency
        final settings = _getSettingsService();
        if (settings != null) {
          gracePeriodDays = settings.gracePeriodDays.value;
          lateFeePercentage = settings.lateFeePercentage.value;
          enableLateFee = settings.enableLateFee.value;
        }
      } catch (_) {}
      
      if (!enableLateFee) return 0;
      
      final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays));
      if (DateTime.now().isAfter(gracePeriodEnd)) {
        return amount * (lateFeePercentage / 100);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  /// Helper to get settings service
  dynamic _getSettingsService() {
    try {
      // Import at runtime to avoid circular dependency
      return _AppSettingsServiceHelper.getService();
    } catch (_) {
      return null;
    }
  }
  
  /// Get total amount including late fee
  double get totalWithLateFee => amount + calculateLateFee();
  
  /// Check if bill is in grace period
  bool get isInGracePeriod {
    final now = DateTime.now();
    int gracePeriodDays = 3;
    
    try {
      final settings = _getSettingsService();
      if (settings != null) {
        gracePeriodDays = settings.gracePeriodDays.value;
      }
    } catch (_) {}
    
    final gracePeriodEnd = dueDate.add(Duration(days: gracePeriodDays));
    return now.isAfter(dueDate) && now.isBefore(gracePeriodEnd) && status != 'paid';
  }
  
  /// Check if bill needs reminder (within X days before due date)
  bool get needsReminder {
    if (status == 'paid') return false;
    
    int reminderDaysBefore = 3;
    bool enableReminders = true;
    
    try {
      final settings = _getSettingsService();
      if (settings != null) {
        reminderDaysBefore = settings.reminderDaysBefore.value;
        enableReminders = settings.enableReminders.value;
      }
    } catch (_) {}
    
    if (!enableReminders) return false;
    
    final reminderDate = dueDate.subtract(Duration(days: reminderDaysBefore));
    final now = DateTime.now();
    return now.isAfter(reminderDate) && now.isBefore(dueDate);
  }
  
  /// Get formatted late fee
  String get formattedLateFee {
    final fee = calculateLateFee();
    if (fee <= 0) return '-';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(fee);
  }

  /// Get formatted amount
  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Get formatted remaining
  String get formattedRemaining {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(remainingAmount);
  }

  /// Get formatted due date
  String get formattedDueDate {
    return DateFormat('dd MMM yyyy', 'id_ID').format(dueDate);
  }

  /// Get billing period label
  String get billingPeriodLabel {
    final startMonth = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(billingPeriodStart);
    return startMonth;
  }

  /// Get status color hex
  String get statusColor {
    switch (status) {
      case 'paid':
        return '#B9F3CC'; // softGreen
      case 'verified':
        return '#A9C9FF'; // pastelBlue
      case 'pending':
        return '#FFD6A5'; // warmPeach
      case 'overdue':
        return '#F7C4D4'; // softPink
      default:
        return '#A9C9FF';
    }
  }

  /// Get status label in Indonesian
  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Lunas';
      case 'verified':
        return 'Terverifikasi';
      case 'pending':
        return 'Menunggu';
      case 'overdue':
        return 'Terlambat';
      default:
        return status;
    }
  }

  /// Get type label in Indonesian
  String get typeLabel {
    switch (type) {
      case 'sewa':
        return 'Sewa Kamar';
      case 'listrik':
        return 'Listrik';
      case 'air':
        return 'Air';
      case 'deposit':
        return 'Deposit';
      case 'denda':
        return 'Denda';
      case 'lainnya':
        return 'Lainnya';
      default:
        return type;
    }
  }
}

/// Payment model for bill payments
class Payment {
  final String id;
  final String billId;
  final double amount;
  final String method; // transfer, cash, ewallet
  final String status; // pending, verified, rejected
  final String? proofUrl;
  final String? notes;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  Payment({
    required this.id,
    required this.billId,
    required this.amount,
    required this.method,
    required this.status,
    this.proofUrl,
    this.notes,
    required this.paymentDate,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String? ?? 'transfer',
      status: json['status'] as String? ?? 'pending',
      proofUrl: json['proof_url'] as String?,
      notes: json['notes'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      verifiedBy: json['verified_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bill_id': billId,
      'amount': amount,
      'method': method,
      'status': status,
      'proof_url': proofUrl,
      'notes': notes,
      'payment_date': paymentDate.toIso8601String().split('T').first,
    };
  }

  /// Get formatted amount
  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Get method label
  String get methodLabel {
    switch (method) {
      case 'transfer':
        return 'Transfer Bank';
      case 'cash':
        return 'Tunai';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return method;
    }
  }

  /// Get status label
  String get statusLabel {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }
}

/// Bill status enum
class BillStatus {
  static const String pending = 'pending';
  static const String verified = 'verified';
  static const String paid = 'paid';
  static const String overdue = 'overdue';

  static List<String> get all => [pending, verified, paid, overdue];

  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Menunggu';
      case verified:
        return 'Terverifikasi';
      case paid:
        return 'Lunas';
      case overdue:
        return 'Terlambat';
      default:
        return status;
    }
  }
}

/// Bill type enum
class BillType {
  static const String sewa = 'sewa';
  static const String listrik = 'listrik';
  static const String air = 'air';
  static const String deposit = 'deposit';
  static const String denda = 'denda';
  static const String lainnya = 'lainnya';

  static List<String> get all => [sewa, listrik, air, deposit, denda, lainnya];

  static String getLabel(String type) {
    switch (type) {
      case sewa:
        return 'Sewa Kamar';
      case listrik:
        return 'Listrik';
      case air:
        return 'Air';
      case deposit:
        return 'Deposit';
      case denda:
        return 'Denda';
      case lainnya:
        return 'Lainnya';
      default:
        return type;
    }
  }
}
