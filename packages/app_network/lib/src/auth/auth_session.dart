import "dart:async";

import "package:app_network/src/contracts/auth_policy.dart";
import "package:app_network/src/contracts/network_credentials.dart";
import "package:app_network/src/contracts/network_failure.dart";
import "package:app_network/src/contracts/network_result.dart";
import "package:app_network/src/contracts/token_refresher.dart";
import "package:app_network/src/contracts/token_store.dart";

/// Credentials captured for a request, fenced by session and token revision.
final class AuthSnapshot {
  const AuthSnapshot({
    required this.credentials,
    required this.generation,
    required this.revision,
  });

  /// Request-local credentials; never log the contained secrets.
  final NetworkCredentials credentials;

  /// Host login/logout generation.
  final int generation;

  /// Revision advanced by refresh within a generation.
  final int revision;

  @override
  String toString() => "AuthSnapshot($generation, $revision, [redacted])";
}

/// Host-injected session shared by clients, with single-flight refresh and fencing.
/// Only these lifecycle APIs may write the host store after construction.
final class AuthSession {
  AuthSession({
    required TokenStore store,
    required this.mode,
    required UnauthorizedCallback onUnauthorized,
    TokenRefresher? refresher,
  }) : _store = store,
       _refresher = refresher,
       _onUnauthorized = onUnauthorized;

  final TokenStore _store;
  final TokenRefresher? _refresher;
  final UnauthorizedCallback _onUnauthorized;

  /// Configured refresh capability; public calls never enter this session.
  final AuthMode mode;
  NetworkCredentials? _credentials;
  int _generation = 0;
  int _revision = 0;
  bool _closed = false;
  Future<void> _operations = Future<void>.value();
  Future<NetworkResult<AuthSnapshot>>? _restore;
  Future<NetworkResult<AuthSnapshot>>? _refresh;
  Future<NetworkFailure>? _invalidating;
  NetworkFailure _closedFailure = const NetworkFailure(
    NetworkFailureKind.unauthorized,
  );

  /// Current host generation; use to filter delayed unauthorized notifications.
  int get generation => _generation;

  /// True only while both the host session and token revision remain current.
  bool isCurrent(AuthSnapshot snapshot) =>
      !_closed &&
      snapshot.generation == _generation &&
      snapshot.revision == _revision;

  /// Restores once, sharing the read; failed/closed sessions require replacement.
  Future<NetworkResult<AuthSnapshot>> acquire() {
    if (_closed) {
      return _closedResult();
    }
    if (_credentials != null) {
      return Future.value(NetworkResult.success(_snapshot()));
    }
    return _restore ??= _restoreCredentials(_generation);
  }

  Future<NetworkResult<AuthSnapshot>> _closedResult() async {
    final pending = _invalidating;
    return NetworkResult.failure(
      pending == null ? _closedFailure : await pending,
    );
  }

  Future<NetworkResult<AuthSnapshot>> _restoreCredentials(int epoch) async {
    final result = await _serialize(() async {
      try {
        return await _store.read();
      } catch (_) {
        return const NetworkResult<NetworkCredentials?>.failure(
          NetworkFailure(NetworkFailureKind.storage),
        );
      }
    });
    if (epoch != _generation) {
      return _stale();
    }
    if (result case NetworkError<NetworkCredentials?>(:final failure)) {
      return NetworkResult.failure(await _invalidate(epoch, failure));
    }
    final credentials = (result as NetworkSuccess<NetworkCredentials?>).value;
    if (credentials == null) {
      return NetworkResult.failure(
        await _invalidate(
          epoch,
          const NetworkFailure(NetworkFailureKind.unauthorized),
        ),
      );
    }
    _credentials = credentials;
    return NetworkResult.success(_snapshot());
  }

  /// Starts a new login generation immediately, then persists before opening it.
  Future<NetworkResult<void>> replaceCredentials(
    NetworkCredentials credentials,
  ) async {
    final epoch = ++_generation;
    _resetClosed();
    final saved = await _serialize(() => _write(credentials));
    if (epoch != _generation) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.staleSession),
      );
    }
    if (saved case NetworkError<void>(:final failure)) {
      return NetworkResult.failure(await _invalidate(epoch, failure));
    }
    _credentials = credentials;
    _closed = false;
    return const NetworkResult.success(null);
  }

  /// Explicit host logout; fences immediately and clears without unauthorized UI.
  Future<NetworkResult<void>> clearCredentials() async {
    final epoch = ++_generation;
    _resetClosed();
    final result = await _serialize(_clear);
    if (epoch != _generation) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.staleSession),
      );
    }
    if (result case NetworkError<void>(:final failure)) {
      _closedFailure = failure;
    }
    return result;
  }

  void _resetClosed() {
    _closed = true;
    _credentials = null;
    _revision = 0;
    _restore = null;
    _refresh = null;
    _invalidating = null;
    _closedFailure = const NetworkFailure(NetworkFailureKind.unauthorized);
  }

  /// Reuses the newer token for late rejection or shares one refresh per revision.
  Future<NetworkResult<AuthSnapshot>> refreshAfterRejection(
    AuthSnapshot snapshot,
  ) {
    if (snapshot.generation != _generation) {
      return Future.value(_stale());
    }
    if (_closed) {
      return _closedResult();
    }
    if (snapshot.revision != _revision) {
      return acquire();
    }
    final existing = _refresh;
    if (existing != null) {
      return existing;
    }
    final future = _performRefresh(snapshot);
    _refresh = future;
    unawaited(
      future.then((_) {
        if (identical(_refresh, future)) {
          _refresh = null;
        }
      }),
    );
    return future;
  }

  Future<NetworkResult<AuthSnapshot>> _performRefresh(
    AuthSnapshot snapshot,
  ) async {
    final refresher = _refresher;
    if (mode != AuthMode.refreshToken ||
        refresher == null ||
        snapshot.credentials.refreshToken == null) {
      return NetworkResult.failure(
        await _invalidate(
          snapshot.generation,
          const NetworkFailure(NetworkFailureKind.unauthorized),
        ),
      );
    }
    NetworkResult<NetworkCredentials> result;
    try {
      result = await refresher.refresh(snapshot.credentials);
    } catch (_) {
      result = const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.refresh),
      );
    }
    if (!isCurrent(snapshot)) {
      return _stale();
    }
    if (result case NetworkError<NetworkCredentials>(:final failure)) {
      // Offline, timed out or a server error: the refresh token may still be
      // good, so keep the session and let the next request refresh again.
      if (isTransientRefreshFailure(failure)) {
        return NetworkResult.failure(failure);
      }
      return NetworkResult.failure(
        await _invalidate(snapshot.generation, failure),
      );
    }
    final credentials = (result as NetworkSuccess<NetworkCredentials>).value;
    final saved = await _serialize(() {
      if (!isCurrent(snapshot)) {
        return Future.value(
          const NetworkResult<void>.failure(
            NetworkFailure(NetworkFailureKind.staleSession),
          ),
        );
      }
      return _write(credentials);
    });
    if (!isCurrent(snapshot)) {
      return _stale();
    }
    if (saved case NetworkError<void>(:final failure)) {
      return NetworkResult.failure(
        await _invalidate(snapshot.generation, failure),
      );
    }
    _credentials = credentials;
    _revision++;
    return NetworkResult.success(_snapshot());
  }

  /// Invalidates a terminal rejected revision without affecting a newer session.
  Future<NetworkFailure> reject(
    AuthSnapshot snapshot, {
    NetworkFailure failure = const NetworkFailure(
      NetworkFailureKind.unauthorized,
    ),
  }) {
    if (snapshot.generation != _generation || snapshot.revision != _revision) {
      return Future.value(
        const NetworkFailure(NetworkFailureKind.staleSession),
      );
    }
    return _invalidate(snapshot.generation, failure);
  }

  Future<NetworkFailure> _invalidate(int epoch, NetworkFailure reason) {
    if (epoch != _generation) {
      return Future.value(
        const NetworkFailure(NetworkFailureKind.staleSession),
      );
    }
    final existing = _invalidating;
    if (existing != null) {
      return existing;
    }
    _closed = true;
    _credentials = null;
    _closedFailure = reason;
    final future = _cleanup(epoch, reason);
    _invalidating = future;
    return future;
  }

  Future<NetworkFailure> _cleanup(int epoch, NetworkFailure reason) async {
    final cleared = await _serialize(() {
      if (epoch != _generation) {
        return Future.value(const NetworkResult<void>.success(null));
      }
      return _clear();
    });
    final secondary = <NetworkFailure>[
      if (cleared case NetworkError<void>(:final failure)) failure,
    ];
    // Host callbacks run outside the persistence queue and receive their epoch.
    try {
      await _onUnauthorized(
        UnauthorizedEvent(
          generation: epoch,
          failure: reason.withSecondary(secondary),
        ),
      );
    } catch (_) {
      secondary.add(const NetworkFailure(NetworkFailureKind.callback));
    }
    final result = reason.withSecondary(secondary);
    if (epoch == _generation) {
      _closedFailure = result;
    }
    return result;
  }

  Future<NetworkResult<void>> _write(NetworkCredentials credentials) async {
    try {
      return await _store.write(credentials);
    } catch (_) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.storage),
      );
    }
  }

  Future<NetworkResult<void>> _clear() async {
    try {
      return await _store.clear();
    } catch (_) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.storage),
      );
    }
  }

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _operations.then((_) => action());
    _operations = result.then<void>((_) {});
    return result;
  }

  AuthSnapshot _snapshot() => AuthSnapshot(
    credentials: _credentials!,
    generation: _generation,
    revision: _revision,
  );

  NetworkResult<AuthSnapshot> _stale() => const NetworkResult.failure(
    NetworkFailure(NetworkFailureKind.staleSession),
  );
}

/// A refresh that failed for a reason that says nothing about the refresh
/// token: no connection, a timeout, cancellation, rate limiting or a
/// server error. Every other failure (e.g. HTTP 400/401/403, an invalid
/// answer) ends the session.
bool isTransientRefreshFailure(NetworkFailure failure) =>
    switch (failure.kind) {
      NetworkFailureKind.connectivity ||
      NetworkFailureKind.timeout ||
      NetworkFailureKind.cancellation => true,
      NetworkFailureKind.http => switch (failure.statusCode) {
        final int code => code == 429 || code >= 500,
        null => false,
      },
      _ => false,
    };
