import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:app_network/src/contracts/network_failure.dart";
import "package:app_network/src/contracts/network_request.dart";
import "package:app_network/src/contracts/network_response.dart";
import "package:app_network/src/contracts/network_result.dart";
import "package:app_network/src/transport/dio_network_transport.dart";
import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test(
    "buffered multipart sends fresh streams with identical immutable evidence",
    () async {
      final adapter = _Adapter();
      final transport = _transport(adapter);
      final bytes = [65, 66, 67];
      final file = NetworkUpload(
        field: "photo",
        filename: "visit.jpeg",
        contentType: "image/jpeg",
        bytes: bytes,
      );
      bytes[0] = 90;
      final request = NetworkRequest(
        path: "/visits/1/check-in",
        auth: RequestAuth.public,
        method: "POST",
        body: NetworkMultipart(
          fields: {
            "requestId": "same-id",
            "latitude": "16.8",
            "longitude": "96.1",
          },
          files: [file],
        ),
        allowMutationReplay: true,
        idempotencyKey: "same-id",
      );
      for (final attempt in [0, 1]) {
        final result = await transport.send(request);
        expect(result, isA<NetworkSuccess<NetworkResponse<Object?>>>());
        expect(adapter.bodies[attempt], contains("same-id"));
        expect(adapter.bodies[attempt], contains("ABC"));
        expect(adapter.bodies[attempt], contains("image/jpeg"));
        expect(
          adapter.requests[attempt].contentType,
          startsWith("multipart/form-data"),
        );
      }
      expect(file.bytes, [65, 66, 67]);
      expect(() => file.bytes.add(4), throwsUnsupportedError);
      transport.close();
    },
  );
  test("binary requests preserve response bytes", () async {
    final adapter = _Adapter()..payload = "image-bytes";
    final transport = _transport(adapter);
    final result = await transport.send(
      NetworkRequest(
        path: "/photos/check-in",
        auth: RequestAuth.public,
        responseBytes: true,
      ),
    );
    final body =
        (result as NetworkSuccess<NetworkResponse<Object?>>).value.data;
    expect(body, utf8.encode("image-bytes"));
    expect(adapter.requests.single.responseType, ResponseType.bytes);
    transport.close();
  });

  test(
    "AC-5/7 adapter sends buffered JSON and all statuses with safe settings",
    () async {
      final adapter = _Adapter();
      adapter.status = 401;
      final transport = DioNetworkTransport(
        baseUri: Uri.parse("https://api.example.test/v1/"),
        defaultHeaders: {"X-App": "host"},
        connectTimeout: const Duration(seconds: 2),
        sendTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 4),
        adapter: adapter,
      );
      final result = await transport.send(
        NetworkRequest(
          path: "items",
          method: "POST",
          auth: RequestAuth.public,
          query: {"page": 2},
          headers: {"X-Trace": "trace"},
          body: {"name": "item"},
        ),
      );
      final response =
          (result as NetworkSuccess<NetworkResponse<Object?>>).value;
      expect(response.statusCode, 401);
      final options = adapter.requests.single;
      expect(
        options.uri,
        Uri.parse("https://api.example.test/v1/items?page=2"),
      );
      expect(options.method, "POST");
      expect(options.followRedirects, isFalse);
      expect(options.connectTimeout, const Duration(seconds: 2));
      expect(options.sendTimeout, const Duration(seconds: 3));
      expect(options.receiveTimeout, const Duration(seconds: 4));
      expect(options.headers["X-App"], "host");
      expect(options.headers["X-Trace"], "trace");
      expect(
        options.headers.keys.map((key) => key.toLowerCase()),
        isNot(contains("authorization")),
      );
      expect(jsonDecode(adapter.bodies.single), {"name": "item"});
      transport.close();
      expect(adapter.closed, isFalse);
    },
  );

  for (final path in [
    "https://evil.example.test/items",
    "http://api.example.test/items",
    "https://api.example.test:444/items",
    "//evil.example.test/items",
    "https://user:secret@api.example.test/items",
  ]) {
    test("AC-5 rejects untrusted URL $path before sending", () async {
      final adapter = _Adapter();
      final transport = _transport(adapter);
      final result = await transport.send(
        NetworkRequest(
          path: path,
          auth: RequestAuth.protected,
          headers: {"Authorization": "Bearer secret"},
        ),
      );
      expect(_failureOf(result).kind, NetworkFailureKind.invalidRequest);
      expect(adapter.requests, isEmpty);
    });
  }

  test(
    "AC-5 no global auth header; redirects stay raw and unfollowed",
    () async {
      final adapter = _Adapter();
      adapter.status = 302;
      final transport = _transport(adapter);
      expect(
        () => DioNetworkTransport(
          baseUri: Uri.parse("https://api.example.test"),
          defaultHeaders: {"authorization": "secret"},
        ),
        throwsArgumentError,
      );
      expect(
        () => DioNetworkTransport(
          baseUri: Uri.parse("https://api.example.test"),
          defaultHeaders: {"x-access": "secret"},
          authHeaderNames: {"X-Access"},
        ),
        throwsArgumentError,
      );
      final response =
          (await transport.send(
                    NetworkRequest(
                      path: "/items",
                      auth: RequestAuth.protected,
                      headers: {"Authorization": "Bearer access"},
                    ),
                  )
                  as NetworkSuccess<NetworkResponse<Object?>>)
              .value;
      expect(response.statusCode, 302);
      await transport.send(
        NetworkRequest(path: "/public", auth: RequestAuth.public),
      );
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.first.headers["Authorization"], "Bearer access");
      expect(
        adapter.requests.last.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains("authorization")),
      );
      expect(adapter.requests.every((r) => !r.followRedirects), isTrue);
    },
  );

  for (final type in DioExceptionType.values) {
    test("Safety maps Dio $type to sanitized typed failure", () async {
      final adapter = _Adapter();
      adapter.errorType = type;
      final result = await _transport(
        adapter,
      ).send(NetworkRequest(path: "/items", auth: RequestAuth.public));
      final expected = switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => NetworkFailureKind.timeout,
        DioExceptionType.cancel => NetworkFailureKind.cancellation,
        DioExceptionType.badResponse => NetworkFailureKind.http,
        _ => NetworkFailureKind.connectivity,
      };
      expect(_failureOf(result).kind, expected);
      expect(result.toString(), isNot(contains("https://")));
    });
  }

  test("Safety malformed response JSON is decoding failure", () async {
    final adapter = _Adapter();
    adapter.payload = "not-json";
    final result = await _transport(
      adapter,
    ).send(NetworkRequest(path: "/items", auth: RequestAuth.public));
    expect(_failureOf(result).kind, NetworkFailureKind.decoding);
  });

  test(
    "Safety active cancellation reaches dedicated Dio without network",
    () async {
      final adapter = _Adapter();
      adapter.gate = Completer<void>();
      final cancellation = NetworkCancellation();
      final pending = _transport(adapter).send(
        NetworkRequest(
          path: "/items",
          auth: RequestAuth.public,
          cancellation: cancellation,
        ),
      );
      await adapter.entered.future;
      cancellation.cancel();
      expect(_failureOf(await pending).kind, NetworkFailureKind.cancellation);
    },
  );

  test(
    "Safety closed transport and pre-cancelled requests do not send",
    () async {
      final adapter = _Adapter();
      final transport = _transport(adapter);
      final cancellation = NetworkCancellation()..cancel();
      expect(
        _failureOf(
          await transport.send(
            NetworkRequest(
              path: "/items",
              auth: RequestAuth.public,
              cancellation: cancellation,
            ),
          ),
        ).kind,
        NetworkFailureKind.cancellation,
      );
      transport.close();
      expect(
        _failureOf(
          await transport.send(
            NetworkRequest(path: "/items", auth: RequestAuth.public),
          ),
        ).kind,
        NetworkFailureKind.invalidRequest,
      );
      expect(adapter.requests, isEmpty);
      final owned = DioNetworkTransport(
        baseUri: Uri.parse("https://api.example.test"),
      );
      owned.close();
      owned.close();
      expect(
        _failureOf(
          await owned.send(
            NetworkRequest(path: "/items", auth: RequestAuth.public),
          ),
        ).kind,
        NetworkFailureKind.invalidRequest,
      );
    },
  );

  test(
    "Safety rejects streams, raw FormData and mutation without idempotency",
    () {
      expect(
        () => NetworkRequest(
          path: "/items",
          auth: RequestAuth.public,
          body: const Stream<int>.empty(),
        ),
        throwsArgumentError,
      );
      expect(
        () => NetworkRequest(
          path: "/items",
          auth: RequestAuth.public,
          body: FormData(),
        ),
        throwsArgumentError,
      );
      expect(
        () => NetworkRequest(
          path: "/items",
          auth: RequestAuth.protected,
          method: "POST",
          allowMutationReplay: true,
        ),
        throwsArgumentError,
      );
      final source = <String, Object?>{
        "items": <Object?>["original"],
      };
      final request = NetworkRequest(
        path: "/items",
        auth: RequestAuth.public,
        body: source,
      );
      (source["items"]! as List<Object?>).add("changed");
      expect(request.body, {
        "items": ["original"],
      });
    },
  );
}

DioNetworkTransport _transport(_Adapter adapter) => DioNetworkTransport(
  baseUri: Uri.parse("https://api.example.test"),
  adapter: adapter,
);
NetworkFailure _failureOf<T>(NetworkResult<T> result) =>
    (result as NetworkError<T>).failure;

final class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<String> bodies = [];
  int status = 200;
  String payload = "{\"ok\":true}";
  bool closed = false;
  DioExceptionType? errorType;
  Completer<void>? gate;
  final Completer<void> entered = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final chunks = requestStream == null
        ? <int>[]
        : await requestStream.expand((bytes) => bytes).toList();
    bodies.add(utf8.decode(chunks));
    if (!entered.isCompleted) {
      entered.complete();
    }
    final waiting = gate;
    if (waiting != null) {
      await Future.any([waiting.future, ?cancelFuture]);
    }
    final type = errorType;
    if (type != null) {
      throw DioException(requestOptions: options, type: type);
    }
    return ResponseBody.fromString(
      payload,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}
