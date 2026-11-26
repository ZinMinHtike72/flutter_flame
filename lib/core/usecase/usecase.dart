import "package:game_test/core/result/result.dart";

/// A single asynchronous business operation with typed input and outcome.
abstract interface class UseCase<T, Params> {
  /// Executes the operation with caller-supplied parameters.
  Future<Result<T>> call(Params params);
}

/// Marker value for operations with no input.
final class NoParams {
  /// Creates an empty parameter value.
  const NoParams();

  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => 0;
}

/// A business subscription exposed without presentation dependencies.
abstract interface class StreamUseCase<T, Params> {
  /// Watches the operation with typed parameters.
  Stream<T> call(Params params);
}

/// A pure synchronous domain calculation with a typed result boundary.
abstract interface class SyncUseCase<T, Params> {
  Result<T> call(Params params);
}
