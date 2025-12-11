import 'package:flutter/foundation.dart';

/// Centralized logging service for Kos Bae application
/// Replaces direct print() statements with proper logging
class AppLogger {
  static const String _appName = 'KosBae';
  
  /// Log informational message
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('ℹ️ $_appName $prefix: $message');
    }
  }
  
  /// Log success message
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('✅ $_appName $prefix: $message');
    }
  }
  
  /// Log warning message
  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('⚠️ $_appName $prefix: $message');
    }
  }
  
  /// Log error message with optional error object and stack trace
  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('❌ $_appName $prefix: $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
  }
  
  /// Log debug message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('🔍 $_appName $prefix: $message');
    }
  }
  
  /// Log API/Network request
  static void api(String method, String endpoint, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('🌐 $_appName [API]: $method $endpoint');
      if (params != null && params.isNotEmpty) {
        debugPrint('   Params: $params');
      }
    }
  }
  
  /// Log realtime subscription event
  static void realtime(String table, String event) {
    if (kDebugMode) {
      debugPrint('📡 $_appName [Realtime]: $table - $event');
    }
  }
}
