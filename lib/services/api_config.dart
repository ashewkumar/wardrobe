class ApiConfig {
  // Use --dart-define=API_BASE_URL=http://112.196.37.203:8888/api to override.
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://112.196.37.203:8888/api",
  );
  static const String removeBackgroundApiUrl = String.fromEnvironment(
    "REMOVE_BACKGROUND_API_URL",
    defaultValue: "",
  );

  static String get publicBaseUrl {
    final uri = Uri.parse(baseUrl);
    final segments = List<String>.from(uri.pathSegments);
    if (segments.isNotEmpty && segments.last == "api") {
      segments.removeLast();
    }

    final publicUri = uri.replace(pathSegments: segments);
    return publicUri.toString().replaceFirst(RegExp(r'/$'), '');
  }

  static Uri uri(String path, {Map<String, String>? query}) {
    final cleanPath = path.startsWith("/") ? path.substring(1) : path;
    final base = "$baseUrl/$cleanPath";
    final q = (query ?? {}).isEmpty ? null : query;
    return Uri.parse(base).replace(queryParameters: q);
  }

  static Uri removeBackgroundUri() {
    final override = removeBackgroundApiUrl.trim();
    if (override.isNotEmpty) {
      return Uri.parse(override);
    }

    return uri("remove-background");
  }

  static String? imageUrl(dynamic raw) {
    if (raw == null) return null;

    final value = raw.toString().trim();
    if (value.isEmpty) return null;

    final lower = value.toLowerCase();
    if (lower == "null" ||
        lower == "false" ||
        lower == "0" ||
        lower == "[]" ||
        lower == "{}") {
      return null;
    }

    if (RegExp(r'^\d+$').hasMatch(value)) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      if (RegExp(r'/storage/\d+$').hasMatch(parsed.path)) {
        return null;
      }
      return value;
    }

    var normalized = value.replaceAll('\\', '/');
    if (normalized.startsWith('/public/')) {
      normalized = normalized.substring('/public/'.length);
    } else if (normalized.startsWith('public/')) {
      normalized = normalized.substring('public/'.length);
    }

    if (normalized.startsWith('/storage/')) {
      return "$publicBaseUrl$normalized";
    }
    if (normalized.startsWith('storage/')) {
      return "$publicBaseUrl/$normalized";
    }
    if (normalized.startsWith('/uploads/')) {
      return "$publicBaseUrl/storage$normalized";
    }
    if (normalized.startsWith('uploads/')) {
      return "$publicBaseUrl/storage/$normalized";
    }
    if (normalized.startsWith('/')) {
      return "$publicBaseUrl$normalized";
    }

    return null;
  }
}
