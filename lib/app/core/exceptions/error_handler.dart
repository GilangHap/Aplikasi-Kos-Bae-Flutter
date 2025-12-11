// FILE: lib/app/core/exceptions/error_handler.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_exceptions.dart';
import '../logger/app_logger.dart';

/// Centralized error handler for converting various errors to user-friendly messages
class ErrorHandler {
  /// Get user-friendly error message from any error type
  static String getUserFriendlyMessage(dynamic error) {
    // Already an AppException, use its message
    if (error is AppException) {
      return error.userMessage;
    }
    
    // Network errors
    if (error is SocketException || 
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup')) {
      return 'Koneksi internet bermasalah. Periksa koneksi Anda.';
    }
    
    // Supabase/PostgreSQL errors
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }
    
    // Auth errors
    if (error is AuthException) {
      return _handleAuthError(error);
    }
    
    // Storage errors
    if (error is StorageException) {
      return 'Gagal mengupload file. Silakan coba lagi.';
    }
    
    // Timeout errors
    if (error.toString().contains('TimeoutException') ||
        error.toString().contains('timeout')) {
      return 'Koneksi timeout. Silakan coba lagi.';
    }
    
    // Default fallback
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
  
  /// Handle Supabase PostgrestException
  static String _handlePostgrestError(PostgrestException error) {
    AppLogger.error('PostgrestError', error: error, tag: 'ErrorHandler');
    
    switch (error.code) {
      case '23505': // Unique violation
        return 'Data sudah ada. Gunakan data yang berbeda.';
      case '23503': // Foreign key violation
        return 'Data terkait tidak ditemukan.';
      case '22P02': // Invalid text representation
        return 'Format data tidak valid.';
      case '42501': // Permission denied
        return 'Anda tidak memiliki akses untuk melakukan aksi ini.';
      case '42P01': // Undefined table
        return 'Konfigurasi database bermasalah. Hubungi admin.';
      case 'PGRST116': // No rows returned
        return 'Data tidak ditemukan.';
      default:
        return 'Terjadi kesalahan pada server. Coba lagi nanti.';
    }
  }
  
  /// Handle Supabase AuthException
  static String _handleAuthError(AuthException error) {
    AppLogger.error('AuthError', error: error, tag: 'ErrorHandler');
    
    final message = error.toString().toLowerCase();
    
    if (message.contains('invalid login credentials') || 
        message.contains('invalid_credentials')) {
      return 'Email atau password salah.';
    }
    
    if (message.contains('email not confirmed')) {
      return 'Email belum diverifikasi. Cek inbox email Anda.';
    }
    
    if (message.contains('user not found')) {
      return 'Akun tidak ditemukan.';
    }
    
    if (message.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.';
    }
    
    if (message.contains('session expired') || 
        message.contains('refresh_token_not_found')) {
      return 'Sesi login telah berakhir. Silakan login kembali.';
    }
    
    return 'Gagal melakukan autentikasi. Silakan coba lagi.';
  }
  
  /// Convert error to AppException
  static AppException toAppException(dynamic error) {
    if (error is AppException) {
      return error;
    }
    
    if (error is SocketException) {
      return const NetworkException();
    }
    
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return const DuplicateException();
        case '42501':
          return const PermissionException();
        case 'PGRST116':
          return const NotFoundException();
        default:
          return ServerException(error.message);
      }
    }
    
    return ServerException(error.toString());
  }
}
