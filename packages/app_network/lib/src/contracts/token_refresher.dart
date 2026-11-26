import "package:app_network/src/contracts/network_credentials.dart";
import "package:app_network/src/contracts/network_result.dart";

/// Host refresh operation; endpoint, schema and rotation remain host-owned.
abstract interface class TokenRefresher {
  /// Uses a raw/public client, not the authenticated client sharing this session.
  /// Return complete credentials, preserving the refresh token explicitly when
  /// the backend does not rotate it. Invalid responses must return failure.
  Future<NetworkResult<NetworkCredentials>> refresh(
    NetworkCredentials credentials,
  );
}
