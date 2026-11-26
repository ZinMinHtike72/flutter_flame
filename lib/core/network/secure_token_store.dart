import "dart:convert";

import "package:app_network/app_network.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

/// Persists both credentials together under a single OS-secure storage key.
final class SecureTokenStore implements TokenStore {
  /// Injects OS storage, allowing plugin mocks in tests.
  const SecureTokenStore(this._storage);
  final FlutterSecureStorage _storage;
  static const String _key = "auth.credentials";

  @override
  Future<NetworkResult<NetworkCredentials?>> read() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == null || value.isEmpty) {
        return const NetworkResult.success(null);
      }
      final json = jsonDecode(value) as Map<String, dynamic>;
      return NetworkResult.success(
        NetworkCredentials(
          accessToken: json["accessToken"] as String,
          refreshToken: json["refreshToken"] as String?,
        ),
      );
    } catch (_) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.storage),
      );
    }
  }

  @override
  Future<NetworkResult<void>> write(NetworkCredentials credentials) async {
    try {
      await _storage.write(
        key: _key,
        value: jsonEncode({
          "accessToken": credentials.accessToken,
          "refreshToken": credentials.refreshToken,
        }),
      );
      return const NetworkResult.success(null);
    } catch (_) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.storage),
      );
    }
  }

  @override
  Future<NetworkResult<void>> clear() async {
    try {
      await _storage.delete(key: _key);
      return const NetworkResult.success(null);
    } catch (_) {
      return const NetworkResult.failure(
        NetworkFailure(NetworkFailureKind.storage),
      );
    }
  }
}
