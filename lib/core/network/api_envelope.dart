/// Reads only the documented data object; envelope messages are never trusted.
Map<String, dynamic> readEnvelopeData(Object? body) {
  if (body is Map<String, dynamic> && body["data"] is Map<String, dynamic>) {
    return Map<String, dynamic>.from(body["data"] as Map<String, dynamic>);
  }
  throw const FormatException("Invalid API envelope");
}
