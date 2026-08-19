/// Structured API error raised when the Go API returns an error envelope.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final String detail;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.detail = '',
  });

  @override
  String toString() =>
      'ApiException($statusCode, $code, $message${detail.isEmpty ? '' : ': $detail'})';
}

/// Response envelope returned by the Go API.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiException? error;
  final Object? meta;

  const ApiResponse({required this.success, this.data, this.error, this.meta});

  bool get isSuccess => success;
}

/// Thrown when the request could not be delivered (network, timeout).
class ApiNetworkException implements Exception {
  final String message;
  const ApiNetworkException(this.message);

  @override
  String toString() => 'ApiNetworkException($message)';
}

/// Thrown when the server returns an unparseable payload.
class ApiParseException implements Exception {
  final String message;
  const ApiParseException(this.message);

  @override
  String toString() => 'ApiParseException($message)';
}
