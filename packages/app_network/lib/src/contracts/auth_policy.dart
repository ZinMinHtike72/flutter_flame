import "dart:async";

import "package:app_network/src/contracts/network_failure.dart";
import "package:app_network/src/contracts/network_response.dart";

/// Session capability; public requests work independently in either mode.
enum AuthMode { refreshToken, accessTokenOnly }

/// Builds one request-local authentication header value from an access token.
typedef AuthHeaderBuilder = String Function(String accessToken);

/// Classifies backend auth rejection without assuming JWT or payload shape.
typedef AuthRejectionClassifier =
    bool Function(NetworkResponse<Object?> response);

/// Host notification; filter by generation before navigating or changing UI.
typedef UnauthorizedCallback = FutureOr<void> Function(UnauthorizedEvent event);

/// Configurable auth header and rejection policy.
final class AuthPolicy {
  const AuthPolicy({
    this.headerName = "Authorization",
    this.headerBuilder = bearerHeader,
    this.isRejected = http401,
  });

  /// Header to sanitize case-insensitively and replace on protected requests.
  final String headerName;

  /// Builds the configured header from the access token only.
  final AuthHeaderBuilder headerBuilder;

  /// Default rejects 401 only, never ordinary 403/5xx or transport errors.
  final AuthRejectionClassifier isRejected;

  /// Standard Bearer mechanism; never receives a refresh token.
  static String bearerHeader(String accessToken) => "Bearer $accessToken";

  /// Default backend-agnostic rejection classifier.
  static bool http401(NetworkResponse<Object?> response) =>
      response.statusCode == 401;
}

/// Logout signal for the invalidated generation, not an instruction to navigate.
final class UnauthorizedEvent {
  const UnauthorizedEvent({required this.generation, required this.failure});

  /// Session generation that failed; newer host logins must not be logged out.
  final int generation;

  /// Primary rejection plus storage cleanup diagnostics known at notification.
  final NetworkFailure failure;
}
