// FILE: lib/app/utils/validators/room_validator.dart
import '../../models/room_model.dart';
import 'validation_result.dart';

/// Validator for Room model
class RoomValidator {
  /// Valid room statuses
  static const List<String> validStatuses = ['kosong', 'terisi', 'maintenance'];
  
  /// Validate room data
  static ValidationResult validate(Room room) {
    final errors = <String>[];
    
    // Room number validation
    if (room.roomNumber.trim().isEmpty) {
      errors.add('Nomor kamar tidak boleh kosong');
    } else if (room.roomNumber.trim().length > 20) {
      errors.add('Nomor kamar maksimal 20 karakter');
    }
    
    // Price validation
    if (room.price < 0) {
      errors.add('Harga tidak boleh negatif');
    } else if (room.price < 100000) {
      errors.add('Harga minimal Rp 100.000');
    } else if (room.price > 100000000) {
      errors.add('Harga maksimal Rp 100.000.000');
    }
    
    // Status validation
    if (!validStatuses.contains(room.status)) {
      errors.add('Status kamar tidak valid');
    }
    
    // Description validation
    if (room.description.length > 1000) {
      errors.add('Deskripsi maksimal 1000 karakter');
    }
    
    // Photos validation
    if (room.photos.length > 10) {
      errors.add('Maksimal 10 foto per kamar');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
  
  /// Validate room number only
  static String? validateRoomNumber(String? roomNumber) {
    if (roomNumber == null || roomNumber.trim().isEmpty) {
      return 'Nomor kamar tidak boleh kosong';
    }
    if (roomNumber.trim().length > 20) {
      return 'Nomor kamar maksimal 20 karakter';
    }
    return null;
  }
  
  /// Validate price only
  static String? validatePrice(String? priceStr) {
    if (priceStr == null || priceStr.isEmpty) {
      return 'Harga tidak boleh kosong';
    }
    
    final price = double.tryParse(priceStr.replaceAll(RegExp(r'[^\d]'), ''));
    if (price == null) {
      return 'Harga tidak valid';
    }
    if (price < 100000) {
      return 'Harga minimal Rp 100.000';
    }
    if (price > 100000000) {
      return 'Harga maksimal Rp 100.000.000';
    }
    return null;
  }
}
