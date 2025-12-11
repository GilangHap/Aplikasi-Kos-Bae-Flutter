import '../../models/contract_model.dart';
import 'validation_result.dart';

/// Validator for Contract model
class ContractValidator {
  /// Valid contract statuses
  static const List<String> validStatuses = ['aktif', 'akan_habis', 'berakhir'];
  
  /// Validate contract data
  static ValidationResult validate(Contract contract) {
    final errors = <String>[];
    
    // Tenant validation
    if (contract.tenantId.isEmpty) {
      errors.add('Penghuni harus dipilih');
    }
    
    // Room validation
    if (contract.roomId == null || contract.roomId!.isEmpty) {
      errors.add('Kamar harus dipilih');
    }
    
    // Monthly rent validation
    if (contract.monthlyRent <= 0) {
      errors.add('Biaya sewa bulanan harus lebih dari 0');
    } else if (contract.monthlyRent > 100000000) {
      errors.add('Biaya sewa maksimal Rp 100.000.000');
    }
    
    // Date validation
    if (contract.endDate.isBefore(contract.startDate)) {
      errors.add('Tanggal selesai harus setelah tanggal mulai');
    }
    
    // Minimum contract duration (1 month)
    final duration = contract.endDate.difference(contract.startDate).inDays;
    if (duration < 30) {
      errors.add('Durasi kontrak minimal 1 bulan');
    }
    
    // Maximum contract duration (5 years)
    if (duration > 1825) {
      errors.add('Durasi kontrak maksimal 5 tahun');
    }
    
    // Status validation
    if (!validStatuses.contains(contract.status)) {
      errors.add('Status kontrak tidak valid');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
  
  /// Validate monthly rent only
  static String? validateMonthlyRent(String? rentStr) {
    if (rentStr == null || rentStr.isEmpty) {
      return 'Biaya sewa tidak boleh kosong';
    }
    
    final rent = double.tryParse(rentStr.replaceAll(RegExp(r'[^\d]'), ''));
    if (rent == null) {
      return 'Biaya sewa tidak valid';
    }
    if (rent <= 0) {
      return 'Biaya sewa harus lebih dari 0';
    }
    if (rent > 100000000) {
      return 'Biaya sewa maksimal Rp 100.000.000';
    }
    return null;
  }
  
  /// Validate date range
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) {
      return 'Tanggal mulai harus dipilih';
    }
    if (endDate == null) {
      return 'Tanggal selesai harus dipilih';
    }
    if (endDate.isBefore(startDate)) {
      return 'Tanggal selesai harus setelah tanggal mulai';
    }
    final duration = endDate.difference(startDate).inDays;
    if (duration < 30) {
      return 'Durasi kontrak minimal 1 bulan';
    }
    return null;
  }
}
