// FILE: lib/app/utils/validators/complaint_validator.dart
import '../../models/complaint_model.dart';
import 'validation_result.dart';

/// Validator for Complaint model
class ComplaintValidator {
  /// Valid complaint categories
  static const List<String> validCategories = [
    'fasilitas', 'kebersihan', 'keamanan', 'listrik', 'air', 'lainnya'
  ];
  
  /// Valid complaint statuses
  static const List<String> validStatuses = ['submitted', 'in_progress', 'resolved'];
  
  /// Valid priority levels
  static const List<String> validPriorities = ['low', 'medium', 'high'];
  
  /// Validate complaint data
  static ValidationResult validate(Complaint complaint) {
    final errors = <String>[];
    
    // Title validation
    if (complaint.title.trim().isEmpty) {
      errors.add('Judul keluhan tidak boleh kosong');
    } else if (complaint.title.trim().length < 5) {
      errors.add('Judul keluhan minimal 5 karakter');
    } else if (complaint.title.trim().length > 200) {
      errors.add('Judul keluhan maksimal 200 karakter');
    }
    
    // Description validation
    if (complaint.description.trim().isEmpty) {
      errors.add('Deskripsi keluhan tidak boleh kosong');
    } else if (complaint.description.trim().length < 10) {
      errors.add('Deskripsi keluhan minimal 10 karakter');
    } else if (complaint.description.trim().length > 2000) {
      errors.add('Deskripsi keluhan maksimal 2000 karakter');
    }
    
    // Category validation
    if (!validCategories.contains(complaint.category)) {
      errors.add('Kategori keluhan tidak valid');
    }
    
    // Attachments validation
    if (complaint.attachments.length > 5) {
      errors.add('Maksimal 5 lampiran');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
  
  /// Validate title only
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Judul tidak boleh kosong';
    }
    if (title.trim().length < 5) {
      return 'Judul minimal 5 karakter';
    }
    if (title.trim().length > 200) {
      return 'Judul maksimal 200 karakter';
    }
    return null;
  }
  
  /// Validate description only
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Deskripsi tidak boleh kosong';
    }
    if (description.trim().length < 10) {
      return 'Deskripsi minimal 10 karakter';
    }
    if (description.trim().length > 2000) {
      return 'Deskripsi maksimal 2000 karakter';
    }
    return null;
  }
}
