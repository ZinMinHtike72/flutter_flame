/// Categories surfaced to presentation without retaining credentials.
enum AppFailureKind { unauthorized, network, serviceUnavailable, unexpected }

/// A sanitized application failure.
final class AppFailure {
  /// Creates a failure of the specified kind.
  const AppFailure(this.kind, {this.statusCode, this.message});

  /// The failure category.
  final AppFailureKind kind;
  final int? statusCode;
  final String? message;
}

/// An exhaustive success or failure boundary.
sealed class Result<T> {
  /// Creates a result for subclasses.
  const Result();

  /// Completes with a value.
  const factory Result.success(T value) = ResultSuccess<T>;

  /// Completes with a sanitized failure.
  const factory Result.failure(AppFailure failure) = ResultFailure<T>;
}

/// A completed value.
final class ResultSuccess<T> extends Result<T> {
  /// Creates a success.
  const ResultSuccess(this.value);

  /// The completed value.
  final T value;
}

/// An operation that did not complete successfully.
final class ResultFailure<T> extends Result<T> {
  /// Creates a failure result.
  const ResultFailure(this.failure);

  /// The sanitized failure.
  final AppFailure failure;
}
