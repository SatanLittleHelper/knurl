enum ApiErrorCode { unauthorized, notFound, serverError, networkError }

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final ApiErrorCode code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException(${code.name}, $statusCode): $message';
}
