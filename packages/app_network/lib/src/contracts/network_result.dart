import "package:app_network/src/contracts/network_failure.dart";

/// Exhaustive typed boundary for host, transport and client operations.
sealed class NetworkResult<T> {
  const NetworkResult();

  /// A completed value, without exposing it through diagnostics.
  const factory NetworkResult.success(T value) = NetworkSuccess<T>;

  /// A sanitized failure with any secondary cleanup failures retained.
  const factory NetworkResult.failure(NetworkFailure failure) = NetworkError<T>;
}

/// Successful operation; pattern-match to access [value].
final class NetworkSuccess<T> extends NetworkResult<T> {
  const NetworkSuccess(this.value);

  /// Completed operation value.
  final T value;

  @override
  String toString() => "NetworkSuccess";
}

/// Failed operation; pattern-match to inspect [failure].
final class NetworkError<T> extends NetworkResult<T> {
  const NetworkError(this.failure);

  /// Sanitized primary and secondary failures.
  final NetworkFailure failure;

  @override
  String toString() => "NetworkError($failure)";
}
