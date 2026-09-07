/// Represents an error returned by the Vamo backend.
///
/// Maps directly to the `ErrorResponse` schema in the OpenAPI spec.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.errors = const [],
  });

  /// Human-readable error message (Arabic or English from backend).
  final String message;

  /// HTTP status code, if available.
  final int? statusCode;

  /// Detailed field-level errors returned by the backend.
  final List<String> errors;

  /// Creates an [ApiException] from a decoded backend `ErrorResponse` JSON.
  factory ApiException.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiException(
      json['message']?.toString() ?? 'حدث خطأ غير متوقع.',
      statusCode: statusCode ?? (json['status'] as int?),
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
    );
  }

  /// True when the backend explicitly returned 401/403 (authentication issue).
  bool get isAuthError =>
      statusCode == 401 || statusCode == 403;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message, errors: $errors)';
}