import "package:app_network/src/contracts/network_credentials.dart";
import "package:app_network/src/contracts/network_result.dart";

/// Host-owned secure persistence. All session operations await these results.
abstract interface class TokenStore {
  /// Restores credentials; null means no persisted session.
  Future<NetworkResult<NetworkCredentials?>> read();

  /// Atomically persists the complete replacement before it becomes usable.
  Future<NetworkResult<void>> write(NetworkCredentials credentials);

  /// Clears credentials only; unrelated host data must not be removed.
  Future<NetworkResult<void>> clear();
}
