abstract final class ApiConstants {
  static const String basePath = "/";

  static Uri baseUri(String baseUrl) => Uri.parse(baseUrl).resolve(basePath);
}
