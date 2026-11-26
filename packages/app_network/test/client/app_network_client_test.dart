import "dart:async";

import "package:app_network/src/auth/auth_session.dart";
import "package:app_network/src/client/app_network_client.dart";
import "package:app_network/src/contracts/auth_policy.dart";
import "package:app_network/src/contracts/network_credentials.dart";
import "package:app_network/src/contracts/network_failure.dart";
import "package:app_network/src/contracts/network_request.dart";
import "package:app_network/src/contracts/network_response.dart";
import "package:app_network/src/contracts/network_result.dart";
import "package:app_network/src/contracts/network_transport.dart";
import "package:app_network/src/contracts/token_refresher.dart";
import "package:app_network/src/contracts/token_store.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test(
    "AC-1/5 refresh replays once with new auth and identical fields",
    () async {
      final fixture = _Fixture();
      final transport = _Transport(
        (request) async => _response(
          request.headers["Authorization"] == "Bearer old" ? 401 : 200,
        ),
      );
      final client = AppNetworkClient(
        transport: transport,
        session: fixture.session,
      );
      final request = NetworkRequest(
        path: "/items",
        auth: RequestAuth.protected,
        query: {"page": 2},
        headers: {"authorization": "wrong", "X-Trace": "trace"},
      );
      final result = await client.send(request, decode: _decode);
      expect(_valueOf(result).data, "ok");
      expect(transport.calls, hasLength(2));
      expect(transport.calls.last.headers, {
        "X-Trace": "trace",
        "Authorization": "Bearer new",
      });
      expect(transport.calls.last.query, {"page": 2});
      expect(fixture.store.credentials?.refreshToken, "rotated");
      expect(fixture.refresher.calls, 1);
      expect(fixture.events, isEmpty);
    },
  );

  test("AC-1 second auth rejection logs out with no second refresh", () async {
    final fixture = _Fixture();
    final transport = _Transport((_) async => _response(401));
    final client = AppNetworkClient(
      transport: transport,
      session: fixture.session,
    );
    final result = await client.send(_request(), decode: _decode);
    expect(_failureOf(result).kind, NetworkFailureKind.unauthorized);
    expect(transport.calls, hasLength(2));
    expect(fixture.refresher.calls, 1);
    expect(fixture.store.clears, 1);
    expect(fixture.events, hasLength(1));
    await client.send(_request(), decode: _decode);
    expect(transport.calls, hasLength(2));
  });

  for (final status in [200, 401]) {
    test(
      "AC-7 public $status never touches credentials, even after logout",
      () async {
        final fixture = _Fixture();
        final transport = _Transport((_) async => _response(status));
        final client = AppNetworkClient(
          transport: transport,
          session: fixture.session,
        );
        await client.send(
          NetworkRequest(
            path: "/public",
            auth: RequestAuth.public,
            headers: {"Authorization": "must-not-send"},
          ),
          decode: _decode,
        );
        expect(fixture.store.reads, 0);
        expect(fixture.store.clears, 0);
        expect(fixture.refresher.calls, 0);
        expect(fixture.events, isEmpty);
        expect(transport.calls.single.headers, isEmpty);
        await fixture.session.clearCredentials();
        final result = await client.send(
          NetworkRequest(path: "/public", auth: RequestAuth.public),
          decode: _decode,
        );
        expect(
          result,
          status == 200
              ? isA<NetworkSuccess<NetworkResponse<String>>>()
              : isA<NetworkError<NetworkResponse<String>>>(),
        );
        expect(fixture.store.reads, 0);
        expect(fixture.events, isEmpty);
      },
    );
  }

  for (final mode in AuthMode.values) {
    test("AC-5 custom mechanism sanitizes header casing in $mode", () async {
      final fixture = _Fixture(mode: mode);
      final transport = _Transport((_) async => _response(200));
      final client = AppNetworkClient(
        transport: transport,
        session: fixture.session,
        policy: AuthPolicy(
          headerName: "X-Access",
          headerBuilder: (token) => "Token $token",
        ),
      );
      await client.send(
        NetworkRequest(
          path: "/items",
          auth: RequestAuth.protected,
          headers: {"x-access": "bad", "AUTHORIZATION": "bad", "X-Trace": "ok"},
        ),
        decode: _decode,
      );
      expect(transport.calls.single.headers, {
        "X-Trace": "ok",
        "X-Access": "Token old",
      });
      expect(
        transport.calls.single.toString(),
        isNot(contains("refresh-secret")),
      );
    });
  }

  test("AC-4 access-only rejection never refreshes or replays", () async {
    final fixture = _Fixture(mode: AuthMode.accessTokenOnly);
    final transport = _Transport((_) async => _response(401));
    final client = AppNetworkClient(
      transport: transport,
      session: fixture.session,
    );
    expect(
      _failureOf(await client.send(_request(), decode: _decode)).kind,
      NetworkFailureKind.unauthorized,
    );
    expect(transport.calls, hasLength(1));
    expect(fixture.refresher.calls, 0);
    expect(fixture.events, hasLength(1));
  });

  for (final status in [403, 500]) {
    test("Safety ordinary $status is HTTP failure without logout", () async {
      final fixture = _Fixture();
      final client = AppNetworkClient(
        transport: _Transport((_) async => _response(status)),
        session: fixture.session,
      );
      final failure = _failureOf(
        await client.send(_request(), decode: _decode),
      );
      expect(failure.kind, NetworkFailureKind.http);
      expect(failure.statusCode, status);
      expect(fixture.events, isEmpty);
      expect(fixture.refresher.calls, 0);
    });
  }

  for (final kind in [
    NetworkFailureKind.timeout,
    NetworkFailureKind.connectivity,
    NetworkFailureKind.cancellation,
  ]) {
    test(
      "Safety $kind transport failure remains typed without logout",
      () async {
        final fixture = _Fixture();
        final client = AppNetworkClient(
          transport: _Transport(
            (_) async => NetworkResult.failure(NetworkFailure(kind)),
          ),
          session: fixture.session,
        );
        expect(
          _failureOf(await client.send(_request(), decode: _decode)).kind,
          kind,
        );
        expect(fixture.events, isEmpty);
        expect(fixture.refresher.calls, 0);
      },
    );
  }

  test("Safety decoder failure and custom expiry classifier", () async {
    final fixture = _Fixture();
    final transport = _Transport(
      (request) async => _response(
        request.headers["Authorization"] == "Bearer old" ? 419 : 200,
      ),
    );
    final client = AppNetworkClient(
      transport: transport,
      session: fixture.session,
      policy: AuthPolicy(isRejected: (response) => response.statusCode == 419),
    );
    final result = await client.send<String>(
      _request(),
      decode: (_) => throw FormatException("secret payload"),
    );
    expect(_failureOf(result).kind, NetworkFailureKind.decoding);
    expect(result.toString(), isNot(contains("secret payload")));
    expect(fixture.refresher.calls, 1);
    expect(fixture.events, isEmpty);
  });

  for (final optIn in [false, true]) {
    test(
      "Safety mutation replay opt-in=$optIn with host idempotency",
      () async {
        final fixture = _Fixture();
        final transport = _Transport(
          (request) async => _response(
            request.headers["Authorization"] == "Bearer old" ? 401 : 200,
          ),
        );
        final client = AppNetworkClient(
          transport: transport,
          session: fixture.session,
        );
        final request = NetworkRequest(
          path: "/items",
          method: "POST",
          auth: RequestAuth.protected,
          body: {"name": "item"},
          allowMutationReplay: optIn,
          idempotencyKey: optIn ? "host-key" : null,
        );
        final result = await client.send(request, decode: _decode);
        if (optIn) {
          expect(_valueOf(result).data, "ok");
          expect(transport.calls, hasLength(2));
          expect(transport.calls.last.body, {"name": "item"});
          expect(transport.calls.last.headers["Idempotency-Key"], "host-key");
        } else {
          expect(_failureOf(result).kind, NetworkFailureKind.replayDenied);
          expect(transport.calls, hasLength(1));
        }
        expect(fixture.refresher.calls, 1);
        expect(fixture.events, isEmpty);
      },
    );
  }

  test(
    "AC-3 cancelled waiter leaves shared refresh for another request",
    () async {
      final fixture = _Fixture();
      fixture.refresher.pending =
          Completer<NetworkResult<NetworkCredentials>>();
      final oldRequests = Completer<void>();
      final transport = _Transport((request) async {
        if (request.headers["Authorization"] == "Bearer old") {
          return _response(401);
        }
        return _response(200);
      });
      final client = AppNetworkClient(
        transport: transport,
        session: fixture.session,
      );
      final cancellation = NetworkCancellation();
      final first = client.send(
        _request(cancellation: cancellation),
        decode: _decode,
      );
      await fixture.refresher.entered.future;
      final second = client.send(_request(), decode: _decode);
      // Resolve a transport-observed barrier, not a wall-clock sleep.
      final previous = transport.handler;
      transport.handler = (request) {
        if (!oldRequests.isCompleted) {
          oldRequests.complete();
        }
        return previous(request);
      };
      await oldRequests.future;
      cancellation.cancel();
      expect(_failureOf(await first).kind, NetworkFailureKind.cancellation);
      fixture.refresher.pending!.complete(
        NetworkResult.success(
          NetworkCredentials(accessToken: "new", refreshToken: "rotated"),
        ),
      );
      expect(_valueOf(await second).data, "ok");
      expect(fixture.refresher.calls, 1);
      expect(
        transport.calls.where(
          (r) => r.headers["Authorization"] == "Bearer new",
        ),
        hasLength(1),
      );
    },
  );

  test("AC-3 late old-token rejection reuses new revision", () async {
    final fixture = _Fixture();
    final late = Completer<NetworkResult<NetworkResponse<Object?>>>();
    final entered = Completer<void>();
    final transport = _Transport((request) async {
      if (request.path == "/late" &&
          request.headers["Authorization"] == "Bearer old") {
        entered.complete();
        return late.future;
      }
      return _response(
        request.headers["Authorization"] == "Bearer old" ? 401 : 200,
      );
    });
    final client = AppNetworkClient(
      transport: transport,
      session: fixture.session,
    );
    final slow = client.send(
      NetworkRequest(path: "/late", auth: RequestAuth.protected),
      decode: _decode,
    );
    await entered.future;
    expect(_valueOf(await client.send(_request(), decode: _decode)).data, "ok");
    late.complete(_response(401));
    expect(_valueOf(await slow).data, "ok");
    expect(fixture.refresher.calls, 1);
  });

  for (final newLogin in [false, true]) {
    test(
      "Safety late success after ${newLogin ? "login" : "logout"} is fenced",
      () async {
        final fixture = _Fixture();
        final late = Completer<NetworkResult<NetworkResponse<Object?>>>();
        final entered = Completer<void>();
        final client = AppNetworkClient(
          transport: _Transport((_) {
            entered.complete();
            return late.future;
          }),
          session: fixture.session,
        );
        final pending = client.send(_request(), decode: _decode);
        await entered.future;
        if (newLogin) {
          await fixture.session.replaceCredentials(
            NetworkCredentials(accessToken: "login"),
          );
        } else {
          await fixture.session.clearCredentials();
        }
        late.complete(_response(200));
        expect(_failureOf(await pending).kind, NetworkFailureKind.staleSession);
        expect(fixture.events, isEmpty);
      },
    );
  }

  test(
    "Safety injected classifier exceptions remain typed without logout",
    () async {
      final fixture = _Fixture();
      final client = AppNetworkClient(
        transport: _Transport((_) async => _response(200)),
        session: fixture.session,
        policy: AuthPolicy(isRejected: (_) => throw StateError("secret")),
      );
      expect(
        _failureOf(await client.send(_request(), decode: _decode)).kind,
        NetworkFailureKind.callback,
      );
      expect(fixture.events, isEmpty);
    },
  );

  test("Safety pre-cancelled request never reads or sends", () async {
    final fixture = _Fixture();
    final transport = _Transport((_) async => _response(200));
    final cancellation = NetworkCancellation()..cancel();
    final client = AppNetworkClient(
      transport: transport,
      session: fixture.session,
    );
    expect(
      _failureOf(
        await client.send(
          _request(cancellation: cancellation),
          decode: _decode,
        ),
      ).kind,
      NetworkFailureKind.cancellation,
    );
    expect(transport.calls, isEmpty);
    expect(fixture.store.reads, 0);
  });
}

NetworkRequest _request({NetworkCancellation? cancellation}) => NetworkRequest(
  path: "/items",
  auth: RequestAuth.protected,
  cancellation: cancellation,
);
String _decode(Object? data) => switch (data) {
  final String value => value,
  _ => throw const FormatException("Expected string"),
};

NetworkResult<NetworkResponse<Object?>> _response(
  int status, [
  Object? data = "ok",
]) => NetworkResult.success(NetworkResponse(data: data, statusCode: status));
T _valueOf<T>(NetworkResult<T> result) => (result as NetworkSuccess<T>).value;
NetworkFailure _failureOf<T>(NetworkResult<T> result) =>
    (result as NetworkError<T>).failure;

final class _Store implements TokenStore {
  NetworkCredentials? credentials = NetworkCredentials(
    accessToken: "old",
    refreshToken: "refresh-secret",
  );
  int reads = 0;
  int clears = 0;
  @override
  Future<NetworkResult<NetworkCredentials?>> read() async {
    reads++;
    return NetworkResult.success(credentials);
  }

  @override
  Future<NetworkResult<void>> write(NetworkCredentials value) async {
    credentials = value;
    return const NetworkResult.success(null);
  }

  @override
  Future<NetworkResult<void>> clear() async {
    clears++;
    credentials = null;
    return const NetworkResult.success(null);
  }
}

final class _Refresher implements TokenRefresher {
  int calls = 0;
  Completer<NetworkResult<NetworkCredentials>>? pending;
  final Completer<void> entered = Completer<void>();
  @override
  Future<NetworkResult<NetworkCredentials>> refresh(
    NetworkCredentials credentials,
  ) {
    calls++;
    if (!entered.isCompleted) {
      entered.complete();
    }
    return pending?.future ??
        Future.value(
          NetworkResult.success(
            NetworkCredentials(accessToken: "new", refreshToken: "rotated"),
          ),
        );
  }
}

final class _Fixture {
  _Fixture({AuthMode mode = AuthMode.refreshToken}) {
    session = AuthSession(
      store: store,
      mode: mode,
      refresher: refresher,
      onUnauthorized: events.add,
    );
  }
  final _Store store = _Store();
  final _Refresher refresher = _Refresher();
  final List<UnauthorizedEvent> events = [];
  late final AuthSession session;
}

final class _Transport implements NetworkTransport {
  _Transport(this.handler);
  Future<NetworkResult<NetworkResponse<Object?>>> Function(NetworkRequest)
  handler;
  final List<NetworkRequest> calls = [];
  @override
  Future<NetworkResult<NetworkResponse<Object?>>> send(NetworkRequest request) {
    calls.add(request);
    return handler(request);
  }
}
