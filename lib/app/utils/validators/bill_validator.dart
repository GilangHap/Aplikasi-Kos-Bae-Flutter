import '../../models/bill_model.dart';
import 'validation_result.dart';

class BillValidator {
  static const List<String> validTypes = ['sewa', 'listrik', 'air', 'deposit', 'denda', 'lainnya'];
  
  static const List<String> validStatuses = ['pending', 'verified', 'paid', 'overdue'];
  
  /// Validate bill data
  static ValidationResult validate(Bill bill) {
    final errors = <String>[];
    
    // Amount validation
    if (bill.amount <= 0) {
      errors.add('Jumlah tagihan harus lebih dari 0');
    } else if (bill.amount > 1000000000) {
      errors.add('Jumlah tagihan maksimal Rp 1.000.000.000');
    }
    
    // Type validation
    if (!validTypes.contains(bill.type)) {
      errors.add('Tipe tagihan tidak valid');
    }
    
    // Status validation
    if (!validStatuses.contains(bill.status)) {
      errors.add('Status tagihan tidak valid');
    }
    
    // Date validation
    if (bill.billingPeriodEnd.isBefore(bill.billingPeriodStart)) {
      errors.add('Tanggal akhir periode harus setelah tanggal awal');
    }
    
    // Tenant ID validation
    if (bill.tenantId.isEmpty) {
      errors.add('Penghuni harus dipilih');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
  
  /// Validate amount only
  static String? validateAmount(String? amountStr) {
    if (amountStr == null || amountStr.isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }
    
    final amount = double.tryParse(amountStr.replaceAll(RegExp(r'[^\d]'), ''));
    if (amount == null) {
      return 'Jumlah tidak valid';
    }
    if (amount <= 0) {
      return 'Jumlah harus lebih dari 0';
    }
    if (amount > 1000000000) {
      return 'Jumlah maksimal Rp 1.000.000.000';
    }
    return null;
  }
}
