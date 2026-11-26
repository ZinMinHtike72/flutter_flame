import "dart:async";

import "package:app_network/src/auth/auth_session.dart";
import "package:app_network/src/contracts/auth_policy.dart";
import "package:app_network/src/contracts/network_credentials.dart";
import "package:app_network/src/contracts/network_failure.dart";
import "package:app_network/src/contracts/network_result.dart";
import "package:app_network/src/contracts/token_refresher.dart";
import "package:app_network/src/contracts/token_store.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test(
    "AC-1 refresh persists complete rotated credentials before release",
    () async {
      final old = NetworkCredentials(accessToken: "old", refreshToken: "r1");
      final rotated = NetworkCredentials(
        accessToken: "new",
        refreshToken: "r2",
      );
      final store = _FakeTokenStore(old);
      final refresher = _FakeRefresher(
        (_) async => NetworkResult.success(rotated),
      );
      final logout = _FakeLogout();
      final session = AuthSession(
        store: store,
        mode: AuthMode.refreshToken,
        refresher: refresher,
        onUnauthorized: logout.call,
      );
      final initial = _valueOf(await session.acquire());
      final refreshed = _valueOf(await session.refreshAfterRejection(initial));
      expect(refreshed.credentials.accessToken, "new");
      expect(store.credentials?.refreshToken, "r2");
      expect(store.writes, 1);
      expect(refresher.calls, [old]);
      expect(logout.events, isEmpty);
    },
  );

  test("AC-3 concurrent and late old-token rejections share refresh", () async {
    final store = _FakeTokenStore(_old());
    final pending = Completer<NetworkResult<NetworkCredentials>>();
    final refresher = _FakeRefresher((_) => pending.future);
    final logout = _FakeLogout();
    final session = _session(store, refresher, logout);
    final snapshot = _valueOf(await session.acquire());
    final first = session.refreshAfterRejection(snapshot);
    await refresher.entered.future;
    final second = session.refreshAfterRejection(snapshot);
    expect(refresher.calls, hasLength(1));
    pending.complete(NetworkResult.success(_new()));
    expect(_valueOf(await first).credentials.accessToken, "new");
    expect(_valueOf(await second).credentials.accessToken, "new");
    expect(
      _valueOf(
        await session.refreshAfterRejection(snapshot),
      ).credentials.accessToken,
      "new",
    );
    expect(refresher.calls, hasLength(1));
    expect(store.writes, 1);
  });

  for (final scenario in [
    "refresh",
    "invalid",
    "save",
    "missing",
    "access-only",
  ]) {
    test("AC-2/4 $scenario invalidates once and remains fail closed", () async {
      final store = _FakeTokenStore(
        scenario == "missing" ? NetworkCredentials(accessToken: "old") : _old(),
      );
      final logout = _FakeLogout();
      store.clearFailure = const NetworkFailure(NetworkFailureKind.storage);
      logout.throws = true;
      if (scenario == "save") {
        store.writeFailure = const NetworkFailure(NetworkFailureKind.storage);
      }
      final refresher = _FakeRefresher((_) async {
        if (scenario == "invalid") {
          return NetworkResult.success(NetworkCredentials(accessToken: ""));
        }
        return scenario == "refresh"
            ? const NetworkResult.failure(
                NetworkFailure(NetworkFailureKind.refresh),
              )
            : NetworkResult.success(_new());
      });
      final session = AuthSession(
        store: store,
        mode: scenario == "access-only"
            ? AuthMode.accessTokenOnly
            : AuthMode.refreshToken,
        refresher: refresher,
        onUnauthorized: logout.call,
      );
      final snapshot = _valueOf(await session.acquire());
      final results = await Future.wait([
        session.refreshAfterRejection(snapshot),
        session.refreshAfterRejection(snapshot),
      ]);
      for (final result in results) {
        final failure = _failureOf(result);
        expect(
          failure.kind,
          scenario == "save"
              ? NetworkFailureKind.storage
              : scenario == "missing" || scenario == "access-only"
              ? NetworkFailureKind.unauthorized
              : NetworkFailureKind.refresh,
        );
        expect(
          failure.secondary.map((f) => f.kind),
          containsAll([
            NetworkFailureKind.storage,
            NetworkFailureKind.callback,
          ]),
        );
      }
      expect(store.clears, 1);
      expect(logout.events, hasLength(1));
      expect(await session.acquire(), isA<NetworkError<AuthSnapshot>>());
      expect(store.reads, 1);
      expect(
        refresher.calls.length,
        scenario == "missing" || scenario == "access-only" ? 0 : 1,
      );
      store.writeFailure = null;
      expect(
        await session.replaceCredentials(_new()),
        isA<NetworkSuccess<void>>(),
      );
      expect(_valueOf(await session.acquire()).credentials.accessToken, "new");
    });
  }

  for (final failed in [false, true]) {
    test(
      "Safety late refresh ${failed ? "failure" : "success"} cannot alter new login",
      () async {
        final store = _FakeTokenStore(_old());
        final pending = Completer<NetworkResult<NetworkCredentials>>();
        final refresher = _FakeRefresher((_) => pending.future);
        final logout = _FakeLogout();
        final session = _session(store, refresher, logout);
        final old = _valueOf(await session.acquire());
        final refreshing = session.refreshAfterRejection(old);
        await refresher.entered.future;
        await session.replaceCredentials(
          NetworkCredentials(accessToken: "login"),
        );
        pending.complete(
          failed
              ? const NetworkResult.failure(
                  NetworkFailure(NetworkFailureKind.refresh),
                )
              : NetworkResult.success(_new()),
        );
        expect(
          _failureOf(await refreshing).kind,
          NetworkFailureKind.staleSession,
        );
        expect(store.credentials?.accessToken, "login");
        expect(logout.events, isEmpty);
        expect(session.isCurrent(old), isFalse);
      },
    );
  }

  test(
    "Safety serialized pending refresh save cannot resurrect after logout",
    () async {
      final store = _FakeTokenStore(_old());
      store.writeBarrier = Completer<void>();
      final refresher = _FakeRefresher(
        (_) async => NetworkResult.success(_new()),
      );
      final logout = _FakeLogout();
      final session = _session(store, refresher, logout);
      final old = _valueOf(await session.acquire());
      final refreshing = session.refreshAfterRejection(old);
      await store.writeEntered.future;
      final clearing = session.clearCredentials();
      store.writeBarrier!.complete();
      expect(
        _failureOf(await refreshing).kind,
        NetworkFailureKind.staleSession,
      );
      await clearing;
      expect(store.credentials, isNull);
      expect(await session.acquire(), isA<NetworkError<AuthSnapshot>>());
      expect(logout.events, isEmpty);
    },
  );

  for (final (name, failure) in [
    ("offline", const NetworkFailure(NetworkFailureKind.connectivity)),
    ("timeout", const NetworkFailure(NetworkFailureKind.timeout)),
    (
      "HTTP 503",
      const NetworkFailure(NetworkFailureKind.http, statusCode: 503),
    ),
    (
      "HTTP 429",
      const NetworkFailure(NetworkFailureKind.http, statusCode: 429),
    ),
  ]) {
    test(
      "a $name refresh keeps the session; the next refresh succeeds",
      () async {
        final store = _FakeTokenStore(_old());
        final logout = _FakeLogout();
        var fail = true;
        final refresher = _FakeRefresher(
          (_) async => fail
              ? NetworkResult.failure(failure)
              : NetworkResult.success(_new()),
        );
        final session = _session(store, refresher, logout);
        final snapshot = _valueOf(await session.acquire());

        expect(
          _failureOf(await session.refreshAfterRejection(snapshot)).kind,
          failure.kind,
        );
        expect(store.clears, 0);
        expect(store.credentials?.refreshToken, "r1");
        expect(logout.events, isEmpty);
        expect(session.isCurrent(snapshot), isTrue);

        fail = false;
        final refreshed = _valueOf(
          await session.refreshAfterRejection(snapshot),
        );
        expect(refreshed.credentials.accessToken, "new");
        expect(store.credentials?.refreshToken, "r2");
        expect(refresher.calls, hasLength(2));
      },
    );
  }

  for (final status in [400, 401, 403]) {
    test("a refresh refused with HTTP $status ends the session", () async {
      final store = _FakeTokenStore(_old());
      final logout = _FakeLogout();
      final session = _session(
        store,
        _FakeRefresher(
          (_) async => NetworkResult.failure(
            NetworkFailure(NetworkFailureKind.http, statusCode: status),
          ),
        ),
        logout,
      );
      final snapshot = _valueOf(await session.acquire());
      await session.refreshAfterRejection(snapshot);
      expect(store.clears, 1);
      expect(logout.events, hasLength(1));
      expect(await session.acquire(), isA<NetworkError<AuthSnapshot>>());
    });
  }

  test(
    "Safety storage read failure is typed and concurrent restore reads once",
    () async {
      final store = _FakeTokenStore(_old());
      store.readFailure = const NetworkFailure(NetworkFailureKind.storage);
      final session = _session(
        store,
        _FakeRefresher((_) async => NetworkResult.success(_new())),
        _FakeLogout(),
      );
      final results = await Future.wait([session.acquire(), session.acquire()]);
      expect(
        results.map((r) => _failureOf(r).kind),
        everyElement(NetworkFailureKind.storage),
      );
      expect(store.reads, 1);
    },
  );
}

NetworkFailure _failureOf<T>(NetworkResult<T> result) =>
    (result as NetworkError<T>).failure;

NetworkCredentials _old() =>
    NetworkCredentials(accessToken: "old", refreshToken: "r1");
NetworkCredentials _new() =>
    NetworkCredentials(accessToken: "new", refreshToken: "r2");
AuthSession _session(
  _FakeTokenStore store,
  _FakeRefresher refresher,
  _FakeLogout logout,
) => AuthSession(
  store: store,
  mode: AuthMode.refreshToken,
  refresher: refresher,
  onUnauthorized: logout.call,
);

final class _FakeTokenStore implements TokenStore {
  _FakeTokenStore([this.credentials]);

  NetworkCredentials? credentials;
  int reads = 0;
  int writes = 0;
  int clears = 0;
  NetworkFailure? readFailure;
  NetworkFailure? writeFailure;
  NetworkFailure? clearFailure;
  Completer<void>? writeBarrier;
  final Completer<void> writeEntered = Completer<void>();

  @override
  Future<NetworkResult<NetworkCredentials?>> read() async {
    reads++;
    final failure = readFailure;
    return failure == null
        ? NetworkResult.success(credentials)
        : NetworkResult.failure(failure);
  }

  @override
  Future<NetworkResult<void>> write(NetworkCredentials value) async {
    writes++;
    if (!writeEntered.isCompleted) {
      writeEntered.complete();
    }
    final barrier = writeBarrier;
    if (barrier != null) {
      await barrier.future;
    }
    final failure = writeFailure;
    if (failure != null) {
      return NetworkResult.failure(failure);
    }
    credentials = value;
    return const NetworkResult.success(null);
  }

  @override
  Future<NetworkResult<void>> clear() async {
    clears++;
    final failure = clearFailure;
    if (failure != null) {
      return NetworkResult.failure(failure);
    }
    credentials = null;
    return const NetworkResult.success(null);
  }
}

final class _FakeRefresher implements TokenRefresher {
  _FakeRefresher(this.handler);

  final Future<NetworkResult<NetworkCredentials>> Function(NetworkCredentials)
  handler;
  final List<NetworkCredentials> calls = [];
  final Completer<void> entered = Completer<void>();

  @override
  Future<NetworkResult<NetworkCredentials>> refresh(
    NetworkCredentials credentials,
  ) {
    calls.add(credentials);
    if (!entered.isCompleted) {
      entered.complete();
    }
    return handler(credentials);
  }
}

final class _FakeLogout {
  final List<UnauthorizedEvent> events = [];
  bool throws = false;

  void call(UnauthorizedEvent event) {
    events.add(event);
    if (throws) {
      throw StateError("Host callback failure");
    }
  }
}

T _valueOf<T>(NetworkResult<T> result) => (result as NetworkSuccess<T>).value;
