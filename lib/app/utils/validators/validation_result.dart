// FILE: lib/app/utils/validators/validation_result.dart
/// Result of validation process
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
  });
  
  /// Create successful validation result
  factory ValidationResult.success() => const ValidationResult(isValid: true);
  
  /// Create failed validation result with errors
  factory ValidationResult.failure(List<String> errors) => 
    ValidationResult(isValid: false, errors: errors);
  
  /// Get first error message or null if valid
  String? get firstError => errors.isNotEmpty ? errors.first : null;
  
  /// Get all errors as single string
  String get errorMessage => errors.join('\n');
}
