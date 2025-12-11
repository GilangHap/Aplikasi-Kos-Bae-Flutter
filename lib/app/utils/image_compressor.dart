import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/logger/app_logger.dart';

/// Utility class for image compression before upload
class ImageCompressor {
  /// Maximum file size after compression (in bytes) - 500KB
  static const int maxFileSizeBytes = 500 * 1024;
  
  /// Default compression quality
  static const int defaultQuality = 80;
  
  /// Maximum image dimension
  static const int maxDimension = 1024;

  /// Compress an XFile and return compressed XFile
  /// Reduces file size while maintaining reasonable quality
  static Future<XFile?> compress(
    XFile file, {
    int quality = defaultQuality,
    int minWidth = maxDimension,
    int minHeight = maxDimension,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final originalSize = bytes.length;
      
      AppLogger.debug('Original size: ${_formatSize(originalSize)}', tag: 'ImageCompressor');
      
      // Skip compression if already small enough
      if (originalSize <= maxFileSizeBytes) {
        AppLogger.debug('Image already small enough, skipping compression', tag: 'ImageCompressor');
        return file;
      }
      
      // Compress the image
      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      
      if (compressedBytes == null || compressedBytes.isEmpty) {
        AppLogger.warning('Compression failed, returning original', tag: 'ImageCompressor');
        return file;
      }
      
      final compressedSize = compressedBytes.length;
      AppLogger.success(
        'Compressed: ${_formatSize(originalSize)} → ${_formatSize(compressedSize)} (${_compressionPercentage(originalSize, compressedSize)}% reduced)',
        tag: 'ImageCompressor',
      );
      
      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/compressed_$timestamp.jpg';
      final tempFile = await File(tempPath).writeAsBytes(compressedBytes);
      
      return XFile(tempFile.path);
    } catch (e) {
      AppLogger.error('Error compressing image', error: e, tag: 'ImageCompressor');
      return file; // Return original on error
    }
  }

  /// Compress multiple files
  static Future<List<XFile>> compressMultiple(
    List<XFile> files, {
    int quality = defaultQuality,
  }) async {
    final compressedFiles = <XFile>[];
    
    for (final file in files) {
      final compressed = await compress(file, quality: quality);
      if (compressed != null) {
        compressedFiles.add(compressed);
      }
    }
    
    return compressedFiles;
  }

  /// Format file size to human readable string
  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Calculate compression percentage
  static int _compressionPercentage(int original, int compressed) {
    return ((1 - (compressed / original)) * 100).round();
  }
}
