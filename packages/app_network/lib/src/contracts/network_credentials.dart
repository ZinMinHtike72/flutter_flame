/// Complete host credentials. The package does not infer refresh rotation.
final class NetworkCredentials {
  NetworkCredentials({required this.accessToken, this.refreshToken}) {
    if (accessToken.trim().isEmpty ||
        (refreshToken != null && refreshToken!.trim().isEmpty)) {
      throw ArgumentError("Credentials must contain nonempty tokens");
    }
    if (accessToken.contains("\r") || accessToken.contains("\n")) {
      throw ArgumentError("Access token cannot contain header delimiters");
    }
  }

  /// Secret access credential, attached only to protected requests.
  final String accessToken;

  /// Optional secret used only by the injected refresh operation.
  final String? refreshToken;

  @override
  String toString() => "NetworkCredentials([redacted])";
}
