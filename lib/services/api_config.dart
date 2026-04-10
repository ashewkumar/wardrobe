class ApiConfig {
  // Use --dart-define=API_BASE_URL=http://112.196.37.203:8888/api to override.
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://112.196.37.203:8888/api",
  );

  static Uri uri(
    String path, {
    Map<String, String>? query,
  }) {
    final cleanPath = path.startsWith("/") ? path.substring(1) : path;
    final base = "$baseUrl/$cleanPath";
    final q = (query ?? {}).isEmpty ? null : query;
    return Uri.parse(base).replace(queryParameters: q);
  }
}
