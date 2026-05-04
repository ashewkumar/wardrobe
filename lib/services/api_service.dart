import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_config.dart';

class RemoveBackgroundResult {
  RemoveBackgroundResult({required this.file, this.data});

  final File file;
  final Map<String, dynamic>? data;
}

class ApiService {
  static MediaType _imageContentType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lowerPath.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }

  static String _extensionForContentType(String? contentType) {
    final lower = contentType?.toLowerCase() ?? "";
    if (lower.contains("png")) {
      return "png";
    }
    if (lower.contains("webp")) {
      return "webp";
    }
    return "jpg";
  }

  static String? _extractImageString(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json["image_url"],
      json["url"],
      json["image"],
      json["image_base64"],
      json["base64"],
      json["cutout"],
      json["result"],
      if (json["data"] is Map<String, dynamic>) ...[
        (json["data"] as Map<String, dynamic>)["image_url"],
        (json["data"] as Map<String, dynamic>)["url"],
        (json["data"] as Map<String, dynamic>)["image"],
        (json["data"] as Map<String, dynamic>)["image_base64"],
        (json["data"] as Map<String, dynamic>)["base64"],
        (json["data"] as Map<String, dynamic>)["cutout"],
        (json["data"] as Map<String, dynamic>)["result"],
      ],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }

  static Future<File> _writeProcessedImage(
    List<int> bytes, {
    required String preferredExtension,
  }) async {
    final dir = Directory.systemTemp.createTempSync("wardrobe_bg_");
    final file = File(
      "${dir.path}${Platform.pathSeparator}processed_${DateTime.now().millisecondsSinceEpoch}.$preferredExtension",
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // ================= LOGIN =================

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final url = ApiConfig.uri("loginapp");

    try {
      final res = await http.post(
        url,
        headers: {"Accept": "application/json"},
        body: {"email": email, "password": password},
      );

      print("LOGIN STATUS: ${res.statusCode}");
      print("LOGIN BODY: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["status"] == true) {
          return data;
        }
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
    }

    return null;
  }

  static Map<String, String> _authHeaders(String token) {
    return {"Accept": "application/json", "Authorization": "Bearer $token"};
  }

  static Map<String, dynamic>? _decodeResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      // Fall through to null.
    }
    return null;
  }

  static String? _extractErrorMessage(String body) {
    final decoded = _decodeResponseBody(body);
    if (decoded == null) {
      final text = body.trim();
      return text.isEmpty ? null : text;
    }

    final directMessage = decoded["message"]?.toString().trim();
    if (directMessage != null && directMessage.isNotEmpty) {
      return directMessage;
    }

    final errors = decoded["errors"];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
        }
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }

    return null;
  }

  static Map<String, String> _outfitBodyFields({
    String? methodOverride,
    String? userId,
    required String name,
    String? occasion,
    String? notes,
    required List<String> imageIds,
  }) {
    final fields = <String, String>{
      if (methodOverride != null) "_method": methodOverride,
      if (userId != null) "user_id": userId,
      "name": name,
      if (occasion != null && occasion.trim().isNotEmpty)
        "occasion": occasion.trim(),
      if (notes != null && notes.trim().isNotEmpty) "notes": notes.trim(),
    };

    for (var i = 0; i < imageIds.length; i++) {
      fields["image_ids[$i]"] = imageIds[i];
    }

    return fields;
  }

  // ================= AI OUTFIT =================

  static Future<dynamic> getOutfitSuggestion(
    String token,
    String season,
    String occasion,
    String userId,
  ) async {
    final url = ApiConfig.uri(
      "outfit/suggest",
      query: {"season": season, "occasion": occasion, "user_id": userId},
    );

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print("AI STATUS: ${res.statusCode}");
    print("AI BODY: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }

  static Future<dynamic> getSavedOutfits(String token, String userId) async {
    final url = ApiConfig.uri("outfits", query: {"user_id": userId});

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("GET OUTFITS STATUS: ${res.statusCode}");
      print("GET OUTFITS BODY: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return {
        "status": false,
        "message": _extractErrorMessage(res.body) ?? "Failed to load outfits",
      };
    } catch (e) {
      print("GET OUTFITS ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> createOutfit(
    String token, {
    required String userId,
    required String name,
    String? occasion,
    String? notes,
    required List<String> imageIds,
  }) async {
    final url = ApiConfig.uri("outfits");

    try {
      final res = await http.post(
        url,
        headers: _authHeaders(token),
        body: _outfitBodyFields(
          userId: userId,
          name: name,
          occasion: occasion,
          notes: notes,
          imageIds: imageIds,
        ),
      );

      print("CREATE OUTFIT STATUS: ${res.statusCode}");
      print("CREATE OUTFIT BODY: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }

      return {
        "status": false,
        "message": _extractErrorMessage(res.body) ?? "Failed to save outfit",
      };
    } catch (e) {
      print("CREATE OUTFIT ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> updateOutfit(
    String token,
    String id, {
    String? userId,
    required String name,
    String? occasion,
    String? notes,
    required List<String> imageIds,
  }) async {
    final url = ApiConfig.uri("outfits/$id");

    try {
      final res = await http.post(
        url,
        headers: _authHeaders(token),
        body: _outfitBodyFields(
          methodOverride: "PUT",
          userId: userId,
          name: name,
          occasion: occasion,
          notes: notes,
          imageIds: imageIds,
        ),
      );

      print("UPDATE OUTFIT STATUS: ${res.statusCode}");
      print("UPDATE OUTFIT BODY: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }

      return {
        "status": false,
        "message": _extractErrorMessage(res.body) ?? "Failed to update outfit",
      };
    } catch (e) {
      print("UPDATE OUTFIT ERROR: $e");
    }

    return null;
  }

  // ================= IMPORTANT DATES =================

  static Future<dynamic> getImportantDates(String token, String userId) async {
    final url = ApiConfig.uri("important-dates", query: {"user_id": userId});

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("IMPORTANT DATES ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> createImportantDate(
    String token, {
    required String userId,
    required String title,
    required String date,
    required String occasion,
    required String notes,
  }) async {
    final url = ApiConfig.uri("important-dates");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          "user_id": userId,
          "title": title,
          "date": date,
          "occasion": occasion,
          "notes": notes,
        },
      );

      print("CREATE DATE STATUS: ${res.statusCode}");
      print("CREATE DATE BODY: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("CREATE DATE ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> updateImportantDate(
    String token,
    String id, {
    String? userId,
    required String title,
    required String date,
    required String occasion,
    required String notes,
  }) async {
    final url = ApiConfig.uri("important-dates/$id");

    try {
      // Use POST + _method override for Laravel compatibility
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          if (userId != null) "user_id": userId,
          "_method": "PUT",
          "title": title,
          "date": date,
          "occasion": occasion,
          "notes": notes,
        },
      );

      print("UPDATE DATE STATUS: ${res.statusCode}");
      print("UPDATE DATE BODY: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("UPDATE DATE ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> deleteImportantDate(String token, String id) async {
    final url = ApiConfig.uri("important-dates/$id");

    try {
      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("DELETE DATE STATUS: ${res.statusCode}");
      print("DELETE DATE BODY: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("DELETE DATE ERROR: $e");
    }

    return null;
  }

  // ================= TRAVEL PLANS =================

  static Future<dynamic> getTravelPlans(String token, String userId) async {
    final url = ApiConfig.uri("travel-plans", query: {"user_id": userId});

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("TRAVEL PLANS ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> createTravelPlan(
    String token, {
    required String userId,
    required String destination,
    required String startDate,
    required String endDate,
    String? weather,
    String? notes,
  }) async {
    final url = ApiConfig.uri("travel-plans");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          "user_id": userId,
          "destination": destination,
          "start_date": startDate,
          "end_date": endDate,
          if (weather != null) "weather": weather,
          if (notes != null) "notes": notes,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("CREATE TRAVEL PLAN ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> updateTravelPlan(
    String token,
    String id, {
    String? userId,
    required String destination,
    required String startDate,
    required String endDate,
    String? weather,
    String? notes,
  }) async {
    final url = ApiConfig.uri("travel-plans/$id");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          if (userId != null) "user_id": userId,
          "_method": "PUT",
          "destination": destination,
          "start_date": startDate,
          "end_date": endDate,
          if (weather != null) "weather": weather,
          if (notes != null) "notes": notes,
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("UPDATE TRAVEL PLAN ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> deleteTravelPlan(String token, String id) async {
    final url = ApiConfig.uri("travel-plans/$id");

    try {
      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("DELETE TRAVEL PLAN ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> getTravelItems(String token, String planId) async {
    final url = ApiConfig.uri("travel-plans/$planId/items");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("TRAVEL ITEMS ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> createTravelItem(
    String token,
    String planId, {
    required String userId,
    required String label,
    bool isChecked = false,
  }) async {
    final url = ApiConfig.uri("travel-plans/$planId/items");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          "user_id": userId,
          "label": label,
          "is_checked": isChecked ? "1" : "0",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("CREATE TRAVEL ITEM ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> updateTravelItem(
    String token,
    String id, {
    String? userId,
    required String label,
    bool isChecked = false,
  }) async {
    final url = ApiConfig.uri("travel-items/$id");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          if (userId != null) "user_id": userId,
          "_method": "PUT",
          "label": label,
          "is_checked": isChecked ? "1" : "0",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("UPDATE TRAVEL ITEM ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> deleteTravelItem(String token, String id) async {
    final url = ApiConfig.uri("travel-items/$id");

    try {
      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("DELETE TRAVEL ITEM ERROR: $e");
    }

    return null;
  }

  // ================= IMAGES =================

  static Future<dynamic> getImages(String token, String userId) async {
    final url = ApiConfig.uri("images", query: {"user_id": userId});

    try {
      final res = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("IMAGES ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> deleteImage(String token, String id) async {
    final url = ApiConfig.uri("images/$id");

    try {
      final res = await http.delete(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("DELETE IMAGE ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> updateImage(
    String token,
    String id, {
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    final url = ApiConfig.uri("images/$id");

    try {
      if (imageFile != null) {
        final request = http.MultipartRequest("POST", url);
        request.headers.addAll({
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        });
        request.fields.addAll({"_method": "PUT", ...fields});

        final filePath = imageFile.path;
        final normalizedPath = filePath.replaceAll('\\', '/');
        final fileName = normalizedPath.split('/').last;
        request.files.add(
          await http.MultipartFile.fromPath(
            "image",
            filePath,
            filename: fileName,
            contentType: _imageContentType(filePath),
          ),
        );

        final streamed = await request.send();
        final res = await http.Response.fromStream(streamed);

        if (res.statusCode == 200) {
          return jsonDecode(res.body);
        }
      } else {
        final res = await http.post(
          url,
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
          body: {"_method": "PUT", ...fields},
        );

        if (res.statusCode == 200) {
          return jsonDecode(res.body);
        }
      }
    } catch (e) {
      print("UPDATE IMAGE ERROR: $e");
    }

    return null;
  }

  static Future<RemoveBackgroundResult?> removeBackground(
    String token,
    File imageFile,
  ) async {
    final url = ApiConfig.removeBackgroundUri();

    try {
      final request = http.MultipartRequest("POST", url);
      request.headers.addAll({
        "Accept": "application/json, image/*",
        "Authorization": "Bearer $token",
      });

      final filePath = imageFile.path;
      final normalizedPath = filePath.replaceAll('\\', '/');
      final fileName = normalizedPath.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          filePath,
          filename: fileName,
          contentType: _imageContentType(filePath),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print("REMOVE BACKGROUND STATUS: ${response.statusCode}");
        print("REMOVE BACKGROUND BODY: ${response.body}");
        return null;
      }

      final contentType = response.headers["content-type"];
      if ((contentType ?? "").toLowerCase().startsWith("image/")) {
        final file = await _writeProcessedImage(
          response.bodyBytes,
          preferredExtension: _extensionForContentType(contentType),
        );
        return RemoveBackgroundResult(file: file);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final responseData = decoded["data"];
      final data = responseData is Map<String, dynamic>
          ? responseData
          : responseData is Map
          ? responseData.map((key, value) => MapEntry(key.toString(), value))
          : null;

      final imageString = _extractImageString(decoded);
      if (imageString == null) {
        return null;
      }

      if (imageString.startsWith("http://") ||
          imageString.startsWith("https://")) {
        final remoteResponse = await http.get(Uri.parse(imageString));
        if (remoteResponse.statusCode >= 200 &&
            remoteResponse.statusCode < 300) {
          final file = await _writeProcessedImage(
            remoteResponse.bodyBytes,
            preferredExtension: _extensionForContentType(
              remoteResponse.headers["content-type"],
            ),
          );
          return RemoveBackgroundResult(file: file, data: data);
        }
        return null;
      }

      final base64Payload = imageString.contains(",")
          ? imageString.split(",").last.trim()
          : imageString;

      final file = await _writeProcessedImage(
        base64Decode(base64Payload),
        preferredExtension: _extensionForContentType(contentType),
      );
      return RemoveBackgroundResult(file: file, data: data);
    } catch (e) {
      print("REMOVE BACKGROUND ERROR: $e");
    }

    return null;
  }

  static Future<Map<String, dynamic>?> detectItem(
    String token,
    File imageFile,
  ) async {
    final url = ApiConfig.uri("detect-item");

    try {
      final request = http.MultipartRequest("POST", url);
      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      final filePath = imageFile.path;
      final normalizedPath = filePath.replaceAll('\\', '/');
      final fileName = normalizedPath.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          filePath,
          filename: fileName,
          contentType: _imageContentType(filePath),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        print("DETECT ITEM STATUS: ${response.statusCode}");
        print("DETECT ITEM BODY: ${response.body}");
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      print("DETECT ITEM ERROR: $e");
    }

    return null;
  }

  // ================= INNER CIRCLE =================

  static Future<dynamic> getInnerCirclePosts(
    String token,
    String userId,
  ) async {
    final url = ApiConfig.uri("inner-circle/posts", query: {"user_id": userId});

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("INNER CIRCLE POSTS ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> createInnerCirclePost(
    String token, {
    required String userId,
    required String caption,
    String? imageId,
  }) async {
    final url = ApiConfig.uri("inner-circle/posts");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          "user_id": userId,
          "caption": caption,
          if (imageId != null) "image_id": imageId,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("CREATE INNER CIRCLE POST ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> getInnerCircleInviteLink(
    String token,
    String userId,
  ) async {
    final url = ApiConfig.uri(
      "inner-circle/invite-link",
      query: {"user_id": userId},
    );

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("INNER CIRCLE INVITE LINK ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> sendInnerCircleInvite(
    String token, {
    required String userId,
    required String email,
  }) async {
    final url = ApiConfig.uri("inner-circle/invites");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {"user_id": userId, "email": email},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("SEND INNER CIRCLE INVITE ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> acceptInnerCircleInvite(
    String token, {
    required String code,
  }) async {
    final url = ApiConfig.uri("inner-circle/accept");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {"code": code},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("ACCEPT INNER CIRCLE INVITE ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> likeInnerCirclePost(
    String token,
    String postId,
  ) async {
    final url = ApiConfig.uri("inner-circle/posts/$postId/like");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("LIKE INNER CIRCLE POST ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> unlikeInnerCirclePost(
    String token,
    String postId,
  ) async {
    final url = ApiConfig.uri("inner-circle/posts/$postId/like");

    try {
      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("UNLIKE INNER CIRCLE POST ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> getInnerCircleComments(
    String token,
    String postId,
  ) async {
    final url = ApiConfig.uri("inner-circle/posts/$postId/comments");

    try {
      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("INNER CIRCLE COMMENTS ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> addInnerCircleComment(
    String token,
    String postId, {
    required String comment,
  }) async {
    final url = ApiConfig.uri("inner-circle/posts/$postId/comments");

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {"comment": comment},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("ADD INNER CIRCLE COMMENT ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> deleteInnerCircleComment(
    String token,
    String commentId,
  ) async {
    final url = ApiConfig.uri("inner-circle/comments/$commentId");

    try {
      final res = await http.delete(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("DELETE INNER CIRCLE COMMENT ERROR: $e");
    }

    return null;
  }

  // ================= PROFILE =================

  static Future<dynamic> getProfile(String token) async {
    final url = ApiConfig.uri("profile");

    try {
      final res = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("PROFILE ERROR: $e");
    }

    return null;
  }

  static Future<dynamic> updateProfile(
    String token, {
    String? name,
    String? phone,
    String? location,
  }) async {
    final url = ApiConfig.uri("profile");

    try {
      final res = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {
          "_method": "PUT",
          if (name != null) "name": name,
          if (phone != null) "phone": phone,
          if (location != null) "location": location,
        },
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("PROFILE UPDATE ERROR: $e");
    }

    return null;
  }
}
