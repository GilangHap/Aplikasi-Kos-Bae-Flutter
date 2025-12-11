// FILE: lib/app/core/exceptions/app_exceptions.dart
/// Base exception class for Kos Bae application
abstract class AppException implements Exception {
  final String userMessage;
  final String? technicalMessage;
  final String? code;
  
  const AppException(this.userMessage, {this.technicalMessage, this.code});
  
  @override
  String toString() => 'AppException: $userMessage';
}

/// Network/connectivity related exceptions
class NetworkException extends AppException {
  const NetworkException([String? technicalMessage]) 
    : super(
        'Koneksi internet bermasalah. Periksa koneksi Anda dan coba lagi.',
        technicalMessage: technicalMessage,
        code: 'NETWORK_ERROR',
      );
}

/// Server/API error exceptions
class ServerException extends AppException {
  const ServerException([String? technicalMessage]) 
    : super(
        'Server sedang gangguan. Silakan coba beberapa saat lagi.',
        technicalMessage: technicalMessage,
        code: 'SERVER_ERROR',
      );
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException([String? message, String? technicalMessage]) 
    : super(
        message ?? 'Sesi login telah berakhir. Silakan login kembali.',
        technicalMessage: technicalMessage,
        code: 'AUTH_ERROR',
      );
}

/// Validation exceptions
class ValidationException extends AppException {
  final List<String> errors;
  
  const ValidationException(this.errors) 
    : super(
        errors.isNotEmpty ? errors.first : 'Data tidak valid',
        code: 'VALIDATION_ERROR',
      );
  
  @override
  String toString() => 'ValidationException: ${errors.join(', ')}';
}

/// Not found exceptions
class NotFoundException extends AppException {
  const NotFoundException([String? resource]) 
    : super(
        '${resource ?? 'Data'} tidak ditemukan',
        code: 'NOT_FOUND',
      );
}

/// Permission/authorization exceptions
class PermissionException extends AppException {
  const PermissionException([String? technicalMessage]) 
    : super(
        'Anda tidak memiliki akses untuk melakukan aksi ini.',
        technicalMessage: technicalMessage,
        code: 'PERMISSION_DENIED',
      );
}

/// Duplicate data exception
class DuplicateException extends AppException {
  const DuplicateException([String? field]) 
    : super(
        '${field ?? 'Data'} sudah ada. Gunakan data yang berbeda.',
        code: 'DUPLICATE_ERROR',
      );
}

/// Storage/file related exceptions
class StorageException extends AppException {
  const StorageException([String? technicalMessage]) 
    : super(
        'Gagal mengupload file. Silakan coba lagi.',
        technicalMessage: technicalMessage,
        code: 'STORAGE_ERROR',
      );
}

/// Cache related exceptions
class CacheException extends AppException {
  const CacheException([String? technicalMessage]) 
    : super(
        'Gagal memuat data dari cache.',
        technicalMessage: technicalMessage,
        code: 'CACHE_ERROR',
      );
}
