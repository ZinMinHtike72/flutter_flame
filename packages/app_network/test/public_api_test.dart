import "package:app_network/app_network.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  for (final mode in AuthMode.values) {
    test("AC-6 public barrel supports host contracts in $mode", () async {
      final session = AuthSession(
        store: _HostStore(),
        mode: mode,
        refresher: _HostRefresher(),
        onUnauthorized: (_) {},
      );
      final client = AppNetworkClient(
        transport: _HostTransport(),
        session: session,
      );
      final result = await client.send(
        NetworkRequest(path: "/resource", auth: RequestAuth.protected),
        decode: _decode,
      );
      switch (result) {
        case NetworkSuccess<NetworkResponse<String>>(:final value):
          expect(value.data, "host payload");
        case NetworkError<NetworkResponse<String>>(:final failure):
          fail(failure.toString());
      }
      expect(
        await session.replaceCredentials(
          NetworkCredentials(accessToken: "login"),
        ),
        isA<NetworkSuccess<void>>(),
      );
      expect(await session.clearCredentials(), isA<NetworkSuccess<void>>());
    });
  }

  test(
    "AC-6/7 public-only construction needs no session or token store",
    () async {
      const client = AppNetworkClient(transport: _HostTransport());
      final result = await client.send(
        NetworkRequest(path: "/public", auth: RequestAuth.public),
        decode: _decode,
      );
      expect(
        (result as NetworkSuccess<NetworkResponse<String>>).value.data,
        "host payload",
      );
      final adapter = DioNetworkTransport(
        baseUri: Uri.parse("https://example.test"),
      );
      adapter.close();
    },
  );

  test("Public values reject empty credentials and redact diagnostics", () {
    expect(() => NetworkCredentials(accessToken: ""), throwsArgumentError);
    expect(
      () => NetworkCredentials(accessToken: "access", refreshToken: ""),
      throwsArgumentError,
    );
    final credentials = NetworkCredentials(
      accessToken: "access-secret",
      refreshToken: "refresh-secret",
    );
    expect(credentials.toString(), isNot(contains("access-secret")));
    expect(
      NetworkResult.success(credentials).toString(),
      isNot(contains("refresh-secret")),
    );
    final snapshot = AuthSnapshot(
      credentials: credentials,
      generation: 1,
      revision: 2,
    );
    expect(snapshot.toString(), isNot(contains("access-secret")));
    final response = NetworkResponse(data: "secret-body", statusCode: 200);
    expect(response.toString(), isNot(contains("secret-body")));
  });
}

String _decode(Object? data) => switch (data) {
  final String value => value,
  _ => throw const FormatException("Expected string"),
};

final class _HostStore implements TokenStore {
  NetworkCredentials? _credentials = NetworkCredentials(accessToken: "host");
  @override
  Future<NetworkResult<NetworkCredentials?>> read() async =>
      NetworkResult.success(_credentials);
  @override
  Future<NetworkResult<void>> write(NetworkCredentials credentials) async {
    _credentials = credentials;
    return const NetworkResult.success(null);
  }

  @override
  Future<NetworkResult<void>> clear() async {
    _credentials = null;
    return const NetworkResult.success(null);
  }
}

final class _HostRefresher implements TokenRefresher {
  @override
  Future<NetworkResult<NetworkCredentials>> refresh(
    NetworkCredentials credentials,
  ) async =>
      NetworkResult.success(NetworkCredentials(accessToken: "replacement"));
}

final class _HostTransport implements NetworkTransport {
  const _HostTransport();
  @override
  Future<NetworkResult<NetworkResponse<Object?>>> send(
    NetworkRequest request,
  ) async => NetworkResult.success(
    NetworkResponse(data: "host payload", statusCode: 200),
  );
}
