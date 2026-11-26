import "dart:async";

/// Whether a request participates in the host's authenticated session.
enum RequestAuth { public, protected }

/// Cooperative cancellation independent of any HTTP implementation.
final class NetworkCancellation {
  final Completer<void> _cancelled = Completer<void>();

  /// Completes once cancellation is requested.
  Future<void> get whenCancelled => _cancelled.future;

  /// Whether this request must no longer be sent or delivered.
  bool get isCancelled => _cancelled.isCompleted;

  /// Cancels only this request, never a shared session refresh.
  void cancel() {
    if (!isCancelled) {
      _cancelled.complete();
    }
  }
}

/// An immutable file, buffered so authenticated retries resend identical bytes.
final class NetworkUpload {
  NetworkUpload({
    required this.field,
    required this.filename,
    required this.contentType,
    required List<int> bytes,
  }) : bytes = List<int>.unmodifiable(bytes);
  final String field;
  final String filename;
  final String contentType;
  final List<int> bytes;
}

/// Buffered multipart evidence. A transport creates a fresh stream on every send.
final class NetworkMultipart {
  NetworkMultipart({
    required Map<String, String> fields,
    List<NetworkUpload> files = const [],
  }) : fields = Map.unmodifiable(fields),
       files = List.unmodifiable(files);
  final Map<String, String> fields;
  final List<NetworkUpload> files;
}

/// Immutable buffered JSON or multipart request.
final class NetworkRequest {
  NetworkRequest({
    required this.path,
    required this.auth,
    String method = "GET",
    Map<String, Object?> query = const {},
    Map<String, String> headers = const {},
    Object? body,
    this.allowMutationReplay = false,
    this.idempotencyKey,
    this.cancellation,
    this.responseBytes = false,
  }) : method = method.toUpperCase(),
       query = Map<String, Object?>.unmodifiable({
         for (final entry in query.entries) entry.key: _freeze(entry.value),
       }),
       headers = Map<String, String>.unmodifiable(headers),
       body = body is NetworkMultipart ? body : _freeze(body) {
    if (!RegExp(r"^[A-Z]+$").hasMatch(this.method)) {
      throw ArgumentError("Invalid HTTP method");
    }
    if (allowMutationReplay &&
        (idempotencyKey == null || idempotencyKey!.trim().isEmpty)) {
      throw ArgumentError("Mutation replay requires host idempotency");
    }
  }

  /// Relative path or same-origin absolute URL, checked by the transport.
  final String path;

  /// Requests authenticated binary image evidence instead of JSON.
  final bool responseBytes;

  /// HTTP method, normalized to uppercase.
  final String method;

  /// Explicit public/protected intent; there is no implicit auth inference.
  final RequestAuth auth;

  /// Deeply frozen JSON-compatible query parameters.
  final Map<String, Object?> query;

  /// Request-local headers. Authentication headers are sanitized by the client.
  final Map<String, String> headers;

  /// Deeply frozen JSON-compatible body, or null.
  final Object? body;

  /// Explicit host permission to replay a mutation once.
  final bool allowMutationReplay;

  /// Host-provided idempotency value, sent as Idempotency-Key.
  final String? idempotencyKey;

  /// Optional request-local cancellation signal.
  final NetworkCancellation? cancellation;

  /// Safe methods replay by default; mutations need both explicit safeguards.
  bool get canReplay =>
      const {"GET", "HEAD", "OPTIONS"}.contains(method) ||
      (allowMutationReplay && idempotencyKey != null);

  /// Copies only headers, retaining the exact buffered request and cancellation.
  NetworkRequest withHeaders(Map<String, String> value) => NetworkRequest(
    path: path,
    auth: auth,
    method: method,
    query: query,
    headers: value,
    body: body,
    allowMutationReplay: allowMutationReplay,
    idempotencyKey: idempotencyKey,
    cancellation: cancellation,
    responseBytes: responseBytes,
  );

  @override
  String toString() => "NetworkRequest($method, $auth)";
}

Object? _freeze(Object? value) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double && value.isFinite) {
    return value;
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(value.map(_freeze));
  }
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.unmodifiable({
      for (final entry in value.entries) entry.key: _freeze(entry.value),
    });
  }
  throw ArgumentError("Only buffered JSON values are supported");
}
