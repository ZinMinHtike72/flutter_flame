import "package:app_network/src/auth/auth_session.dart";
import "package:app_network/src/contracts/auth_policy.dart";
import "package:app_network/src/contracts/network_failure.dart";
import "package:app_network/src/contracts/network_request.dart";
import "package:app_network/src/contracts/network_response.dart";
import "package:app_network/src/contracts/network_result.dart";
import "package:app_network/src/contracts/network_transport.dart";

/// Typed request orchestration; no backend decoding or navigation is assumed.
final class AppNetworkClient {
  const AppNetworkClient({
    required NetworkTransport transport,
    AuthSession? session,
    AuthPolicy policy = const AuthPolicy(),
  }) : _transport = transport,
       _session = session,
       _policy = policy;

  final NetworkTransport _transport;
  final AuthSession? _session;
  final AuthPolicy _policy;

  /// Sends once, or replays an eligible refresh-mode rejection at most once.
  /// [decode] is called only for a successful, current, non-cancelled response.
  Future<NetworkResult<NetworkResponse<T>>> send<T>(
    NetworkRequest request, {
    required T Function(Object? data) decode,
    String? Function(Object? data)? decodeError,
  }) async {
    if (_cancelled(request)) {
      return _failure(NetworkFailureKind.cancellation);
    }
    AuthSnapshot? snapshot;
    if (request.auth == RequestAuth.protected) {
      final session = _session;
      if (session == null) {
        return _failure(NetworkFailureKind.unauthorized);
      }
      final acquired = await _wait(session.acquire(), request);
      if (acquired case NetworkError<AuthSnapshot>(:final failure)) {
        return NetworkResult.failure(failure);
      }
      snapshot = (acquired as NetworkSuccess<AuthSnapshot>).value;
    }
    for (final attempt in [0, 1]) {
      if (_cancelled(request)) {
        return _failure(NetworkFailureKind.cancellation);
      }
      if (snapshot != null && !_session!.isCurrent(snapshot)) {
        return _failure(NetworkFailureKind.staleSession);
      }
      NetworkRequest prepared;
      try {
        prepared = _prepare(request, snapshot);
      } catch (_) {
        return _failure(NetworkFailureKind.invalidRequest);
      }
      final result = await _wait(_sendRaw(prepared), request);
      if (_cancelled(request)) {
        return _failure(NetworkFailureKind.cancellation);
      }
      bool rejected = false;
      if (snapshot != null &&
          result is NetworkSuccess<NetworkResponse<Object?>>) {
        try {
          rejected = _policy.isRejected(result.value);
        } catch (_) {
          return _failure(NetworkFailureKind.callback);
        }
      }
      if (snapshot != null && !_session!.isCurrent(snapshot)) {
        // Late old-token auth rejection can reuse the current revision, but
        // a late successful response must never be delivered as current data.
        if (snapshot.generation != _session.generation ||
            result is! NetworkSuccess<NetworkResponse<Object?>> ||
            !rejected) {
          return _failure(NetworkFailureKind.staleSession);
        }
      }
      if (result case NetworkError<NetworkResponse<Object?>>(:final failure)) {
        return NetworkResult.failure(failure);
      }
      final response =
          (result as NetworkSuccess<NetworkResponse<Object?>>).value;
      if (snapshot != null && rejected) {
        final session = _session!;
        if (attempt == 1 || session.mode == AuthMode.accessTokenOnly) {
          return NetworkResult.failure(await session.reject(snapshot));
        }
        final refreshed = await _wait(
          session.refreshAfterRejection(snapshot),
          request,
        );
        if (refreshed case NetworkError<AuthSnapshot>(:final failure)) {
          return NetworkResult.failure(failure);
        }
        snapshot = (refreshed as NetworkSuccess<AuthSnapshot>).value;
        if (_cancelled(request)) {
          return _failure(NetworkFailureKind.cancellation);
        }
        if (!request.canReplay) {
          return _failure(NetworkFailureKind.replayDenied);
        }
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? message;
        try {
          message = decodeError?.call(response.data);
        } catch (_) {
          /* Retain the HTTP failure if the optional decoder rejects its body. */
        }
        return NetworkResult.failure(
          NetworkFailure(
            NetworkFailureKind.http,
            statusCode: response.statusCode,
            message: message,
          ),
        );
      }
      try {
        return NetworkResult.success(
          NetworkResponse(
            data: decode(response.data),
            statusCode: response.statusCode,
            headers: response.headers,
          ),
        );
      } catch (_) {
        return _failure(NetworkFailureKind.decoding);
      }
    }
    return _failure(NetworkFailureKind.unauthorized);
  }

  NetworkRequest _prepare(NetworkRequest request, AuthSnapshot? snapshot) {
    final authName = _policy.headerName.toLowerCase();
    final headers = <String, String>{
      for (final entry in request.headers.entries)
        if (entry.key.toLowerCase() != authName &&
            entry.key.toLowerCase() != "authorization" &&
            (request.idempotencyKey == null ||
                entry.key.toLowerCase() != "idempotency-key"))
          entry.key: entry.value,
      if (request.idempotencyKey != null)
        "Idempotency-Key": request.idempotencyKey!,
      if (snapshot != null)
        _policy.headerName: _policy.headerBuilder(
          snapshot.credentials.accessToken,
        ),
    };
    return request.withHeaders(headers);
  }

  Future<NetworkResult<NetworkResponse<Object?>>> _sendRaw(
    NetworkRequest request,
  ) async {
    try {
      return await _transport.send(request);
    } catch (_) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.connectivity),
      );
    }
  }

  Future<NetworkResult<T>> _wait<T>(
    Future<NetworkResult<T>> future,
    NetworkRequest request,
  ) {
    final cancellation = request.cancellation;
    if (cancellation == null) {
      return future;
    }
    return Future.any([
      future,
      cancellation.whenCancelled.then(
        (_) => NetworkResult<T>.failure(
          const NetworkFailure(NetworkFailureKind.cancellation),
        ),
      ),
    ]);
  }

  bool _cancelled(NetworkRequest request) =>
      request.cancellation?.isCancelled ?? false;

  NetworkResult<NetworkResponse<T>> _failure<T>(NetworkFailureKind kind) =>
      NetworkResult.failure(NetworkFailure(kind));
}
