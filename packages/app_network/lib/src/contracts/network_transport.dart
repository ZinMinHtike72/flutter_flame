import "package:app_network/src/contracts/network_request.dart";
import "package:app_network/src/contracts/network_response.dart";
import "package:app_network/src/contracts/network_result.dart";

/// Raw, auth-independent HTTP port. Return all statuses without auth side effects.
abstract interface class NetworkTransport {
  /// Sends the buffered request with request-local cancellation.
  Future<NetworkResult<NetworkResponse<Object?>>> send(NetworkRequest request);
}
