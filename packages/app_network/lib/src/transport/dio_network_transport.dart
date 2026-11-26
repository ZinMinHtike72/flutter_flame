import "dart:async";

import "package:app_network/src/contracts/network_failure.dart";
import "package:app_network/src/contracts/network_request.dart";
import "package:app_network/src/contracts/network_response.dart";
import "package:app_network/src/contracts/network_result.dart";
import "package:app_network/src/contracts/network_transport.dart";
import "package:dio/dio.dart";

/// Dedicated Dio transport enforcing one trusted origin and no redirects.
/// An injected HTTP adapter remains host-owned; the transport owns its own Dio.
final class DioNetworkTransport implements NetworkTransport {
  DioNetworkTransport({
    required Uri baseUri,
    Map<String, String> defaultHeaders = const {},
    Set<String> authHeaderNames = const {"Authorization"},
    Duration connectTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    HttpClientAdapter? adapter,
  }) : _baseUri = baseUri,
       _ownsAdapter = adapter == null,
       _dio = Dio(
         BaseOptions(
           baseUrl: baseUri.toString(),
           connectTimeout: connectTimeout,
           sendTimeout: sendTimeout,
           receiveTimeout: receiveTimeout,
           followRedirects: false,
           validateStatus: _allStatuses,
           headers: Map<String, String>.from(defaultHeaders),
           contentType: Headers.jsonContentType,
         ),
       ) {
    if (!const {"http", "https"}.contains(baseUri.scheme) ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasFragment ||
        baseUri.hasQuery) {
      throw ArgumentError("Base URI must be a trusted HTTP origin/path");
    }
    final sensitive = {
      "authorization",
      for (final name in authHeaderNames) name.toLowerCase(),
    };
    if (defaultHeaders.keys.any(
      (name) => sensitive.contains(name.toLowerCase()),
    )) {
      throw ArgumentError("Authentication headers must be request-local");
    }
    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
    }
  }

  final Uri _baseUri;
  final Dio _dio;
  final bool _ownsAdapter;
  bool _closed = false;

  /// Sends buffered JSON, returning every HTTP status for client classification.
  @override
  Future<NetworkResult<NetworkResponse<Object?>>> send(
    NetworkRequest request,
  ) async {
    if (_closed) {
      return _failure(NetworkFailureKind.invalidRequest);
    }
    final cancellation = request.cancellation;
    if (cancellation?.isCancelled ?? false) {
      return _failure(NetworkFailureKind.cancellation);
    }
    Uri uri;
    try {
      uri = _baseUri.resolve(request.path);
      if (uri.scheme != _baseUri.scheme ||
          uri.host != _baseUri.host ||
          uri.port != _baseUri.port ||
          uri.userInfo.isNotEmpty ||
          uri.hasFragment) {
        return _failure(NetworkFailureKind.invalidRequest);
      }
    } catch (_) {
      return _failure(NetworkFailureKind.invalidRequest);
    }
    final cancelToken = CancelToken();
    bool finished = false;
    if (cancellation != null) {
      unawaited(
        cancellation.whenCancelled.then((_) {
          if (!finished) {
            cancelToken.cancel();
          }
        }),
      );
    }
    try {
      final response = await _dio.request<Object?>(
        uri.toString(),
        data: switch (request.body) {
          final NetworkMultipart body => FormData.fromMap({
            ...body.fields,
            for (final file in body.files)
              file.field: MultipartFile.fromBytes(
                file.bytes,
                filename: file.filename,
                contentType: DioMediaType.parse(file.contentType),
              ),
          }),
          final body => body,
        },
        queryParameters: request.query,
        options: Options(
          method: request.method,
          headers: request.headers,
          followRedirects: false,
          validateStatus: _allStatuses,
          responseType: request.responseBytes
              ? ResponseType.bytes
              : ResponseType.json,
          contentType: request.body is NetworkMultipart
              ? Headers.multipartFormDataContentType
              : Headers.jsonContentType,
        ),
        cancelToken: cancelToken,
      );
      if (cancellation?.isCancelled ?? false) {
        return _failure(NetworkFailureKind.cancellation);
      }
      return NetworkResult.success(
        NetworkResponse(
          data: response.data,
          statusCode: response.statusCode ?? 0,
          headers: response.headers.map,
        ),
      );
    } on DioException catch (error) {
      return _failure(switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => NetworkFailureKind.timeout,
        DioExceptionType.cancel => NetworkFailureKind.cancellation,
        DioExceptionType.badResponse => NetworkFailureKind.http,
        DioExceptionType.unknown when error.error is FormatException =>
          NetworkFailureKind.decoding,
        DioExceptionType.connectionError ||
        DioExceptionType.badCertificate ||
        DioExceptionType.unknown => NetworkFailureKind.connectivity,
      }, statusCode: error.response?.statusCode);
    } catch (_) {
      return _failure(NetworkFailureKind.connectivity);
    } finally {
      finished = true;
    }
  }

  /// Stops future sends; closes only the HTTP adapter created by this transport.
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (_ownsAdapter) {
      _dio.close(force: true);
    }
  }

  static bool _allStatuses(int? status) => true;

  NetworkResult<NetworkResponse<Object?>> _failure(
    NetworkFailureKind kind, {
    int? statusCode,
  }) => NetworkResult.failure(NetworkFailure(kind, statusCode: statusCode));
}
