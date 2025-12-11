import '../../models/tenant_model.dart';
import 'validation_result.dart';

/// Validator for Tenant model
class TenantValidator {
  /// Phone number regex for Indonesian format (08xxxxxxxxxx)
  static final RegExp _phoneRegex = RegExp(r'^08[0-9]{9,12}$');
  
  /// NIK regex (16 digits)
  static final RegExp _nikRegex = RegExp(r'^[0-9]{16}$');
  
  /// Validate tenant data
  static ValidationResult validate(Tenant tenant) {
    final errors = <String>[];
    
    // Name validation
    if (tenant.name.trim().isEmpty) {
      errors.add('Nama tidak boleh kosong');
    } else if (tenant.name.trim().length < 3) {
      errors.add('Nama minimal 3 karakter');
    } else if (tenant.name.trim().length > 100) {
      errors.add('Nama maksimal 100 karakter');
    }
    
    // Phone validation
    if (tenant.phone.trim().isEmpty) {
      errors.add('Nomor telepon tidak boleh kosong');
    } else if (!_phoneRegex.hasMatch(tenant.phone.replaceAll(RegExp(r'[\s\-]'), ''))) {
      errors.add('Format nomor telepon tidak valid (gunakan format 08xxxxxxxxxx)');
    }
    
    // NIK validation (optional but if provided must be valid)
    if (tenant.nik != null && tenant.nik!.isNotEmpty) {
      if (!_nikRegex.hasMatch(tenant.nik!)) {
        errors.add('NIK harus 16 digit angka');
      }
    }
    
    // Address validation (optional but if provided check length)
    if (tenant.address != null && tenant.address!.length > 500) {
      errors.add('Alamat maksimal 500 karakter');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
  
  /// Validate name only
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (name.trim().length < 3) {
      return 'Nama minimal 3 karakter';
    }
    if (name.trim().length > 100) {
      return 'Nama maksimal 100 karakter';
    }
    return null;
  }
  
  /// Validate phone only
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (!_phoneRegex.hasMatch(cleanPhone)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }
  
  /// Validate NIK only
  static String? validateNik(String? nik) {
    if (nik == null || nik.isEmpty) {
      return null; // Optional field
    }
    if (!_nikRegex.hasMatch(nik)) {
      return 'NIK harus 16 digit angka';
    }
    return null;
  }
}
