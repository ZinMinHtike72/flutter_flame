import "package:app_network/app_network.dart";
import "package:game_test/core/result/result.dart";

/// Converts infrastructure failures into a sanitized application outcome.
AppFailure appFailureOf(NetworkFailure failure) => AppFailure(
  switch (failure.kind) {
    NetworkFailureKind.http => switch (failure.statusCode) {
      401 => AppFailureKind.unauthorized,
      final int status when status >= 500 => AppFailureKind.serviceUnavailable,
      _ => AppFailureKind.unexpected,
    },
    NetworkFailureKind.connectivity ||
    NetworkFailureKind.timeout => AppFailureKind.network,
    NetworkFailureKind.unauthorized ||
    NetworkFailureKind.refresh ||
    NetworkFailureKind.staleSession => AppFailureKind.unauthorized,
    _ => AppFailureKind.unexpected,
  },
  statusCode: failure.statusCode,
);
