import 'package:intl/intl.dart';

class PaymentDetail {
  final String id;
  final String billId;
  final double amount;
  final String method;
  final String status;
  final String? proofUrl;
  final String? notes;
  final String? rejectionReason;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  // Bill info
  final double? billAmount;
  final String? billType;
  final String? billStatus;
  final DateTime? billDueDate;
  final String? billingPeriod;

  // Tenant info
  final String? tenantId;
  final String? tenantName;
  final String? tenantPhone;
  final String? tenantPhoto;

  // Room info
  final String? roomId;
  final String? roomNumber;

  PaymentDetail({
    required this.id,
    required this.billId,
    required this.amount,
    required this.method,
    required this.status,
    this.proofUrl,
    this.notes,
    this.rejectionReason,
    required this.paymentDate,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.billAmount,
    this.billType,
    this.billStatus,
    this.billDueDate,
    this.billingPeriod,
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.tenantPhoto,
    this.roomId,
    this.roomNumber,
  });

  /// Create from Supabase JSON with joins
  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    // Handle joined bill data
    double? billAmount;
    String? billType;
    String? billStatus;
    DateTime? billDueDate;
    String? billingPeriod;
    String? tenantId;
    String? tenantName;
    String? tenantPhone;
    String? tenantPhoto;
    String? roomId;
    String? roomNumber;

    if (json['bills'] != null && json['bills'] is Map) {
      final billData = json['bills'] as Map<String, dynamic>;
      billAmount = (billData['amount'] as num?)?.toDouble();
      billType = billData['type'] as String?;
      billStatus = billData['status'] as String?;
      if (billData['due_date'] != null) {
        billDueDate = DateTime.parse(billData['due_date'] as String);
      }
      if (billData['billing_period_start'] != null) {
        final start = DateTime.parse(
          billData['billing_period_start'] as String,
        );
        billingPeriod = DateFormat('MMMM yyyy', 'id_ID').format(start);
      }

      // Nested tenant data
      if (billData['tenants'] != null && billData['tenants'] is Map) {
        final tenantData = billData['tenants'] as Map<String, dynamic>;
        tenantId = tenantData['id'] as String?;
        tenantName = tenantData['name'] as String?;
        tenantPhone = tenantData['phone'] as String?;
        tenantPhoto = tenantData['photo_url'] as String?;
      }

      // Nested room data
      if (billData['rooms'] != null && billData['rooms'] is Map) {
        final roomData = billData['rooms'] as Map<String, dynamic>;
        roomId = roomData['id'] as String?;
        roomNumber = roomData['room_number'] as String?;
      }
    }

    return PaymentDetail(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String? ?? 'transfer',
      status: json['status'] as String? ?? 'pending',
      proofUrl: json['proof_url'] as String?,
      notes: json['notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      verifiedBy: json['verified_by'] as String?,
      billAmount: billAmount,
      billType: billType,
      billStatus: billStatus,
      billDueDate: billDueDate,
      billingPeriod: billingPeriod,
      tenantId: tenantId,
      tenantName: tenantName,
      tenantPhone: tenantPhone,
      tenantPhoto: tenantPhoto,
      roomId: roomId,
      roomNumber: roomNumber,
    );
  }

  // ==================== HELPERS ====================

  /// Get formatted amount
  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Get formatted bill amount
  String get formattedBillAmount {
    if (billAmount == null) return '-';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(billAmount);
  }

  /// Get formatted payment date
  String get formattedPaymentDate {
    return DateFormat('dd MMM yyyy', 'id_ID').format(paymentDate);
  }

  /// Get formatted created at
  String get formattedCreatedAt {
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(createdAt);
  }

  /// Get formatted verified at
  String? get formattedVerifiedAt {
    if (verifiedAt == null) return null;
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(verifiedAt!);
  }

  /// Get time since upload
  String get timeSinceUpload {
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

  /// Get bill type label
  String get billTypeLabel {
    switch (billType) {
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
        return billType ?? '-';
    }
  }

  /// Check if has proof
  bool get hasProof => proofUrl != null && proofUrl!.isNotEmpty;

  /// Check if is pending
  bool get isPending => status == 'pending';

  /// Check if is verified
  bool get isVerified => status == 'verified';

  /// Check if is rejected
  bool get isRejected => status == 'rejected';
}

/// Payment status constants
class PaymentStatus {
  static const String pending = 'pending';
  static const String verified = 'verified';
  static const String rejected = 'rejected';

  static List<String> get all => [pending, verified, rejected];

  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Menunggu';
      case verified:
        return 'Terverifikasi';
      case rejected:
        return 'Ditolak';
      default:
        return status;
    }
  }
}
