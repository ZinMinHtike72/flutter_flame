/// Schema-independent HTTP response with a caller-decoded payload.
final class NetworkResponse<T> {
  NetworkResponse({
    required this.data,
    required this.statusCode,
    Map<String, List<String>> headers = const {},
  }) : headers = Map<String, List<String>>.unmodifiable({
         for (final entry in headers.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       });

  /// Raw transport data or the caller's decoded value.
  final T data;

  /// HTTP status, including non-success statuses.
  final int statusCode;

  /// Response headers; not included in diagnostics.
  final Map<String, List<String>> headers;

  @override
  String toString() => "NetworkResponse(status: $statusCode)";
}
