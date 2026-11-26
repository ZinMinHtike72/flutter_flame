/// Stable failure categories; never carry raw exceptions, URLs or bodies.
enum NetworkFailureKind {
  http,
  connectivity,
  timeout,
  cancellation,
  decoding,
  storage,
  refresh,
  unauthorized,
  replayDenied,
  staleSession,
  invalidRequest,
  callback,
}

/// Sanitized diagnostic boundary, retaining cleanup errors independently.
final class NetworkFailure {
  const NetworkFailure(
    this.kind, {
    this.statusCode,
    this.message,
    this.secondary = const [],
  });

  /// Primary failure category.
  final NetworkFailureKind kind;

  /// HTTP status only; no response or request content is retained.
  final int? statusCode;

  /// Optional host-decoded, display-safe server message. Never included in logs.
  final String? message;

  /// Cleanup/storage/callback failures that must not hide the primary reason.
  final List<NetworkFailure> secondary;

  /// Copies the primary failure with immutable secondary diagnostics.
  NetworkFailure withSecondary(List<NetworkFailure> failures) => NetworkFailure(
    kind,
    statusCode: statusCode,
    message: message,
    secondary: List<NetworkFailure>.unmodifiable([...secondary, ...failures]),
  );

  @override
  String toString() =>
      "NetworkFailure(${kind.name}, status: $statusCode, "
      "secondary: ${secondary.map((failure) => failure.kind.name).join(",")})";
}
