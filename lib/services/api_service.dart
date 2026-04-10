import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {

  // ================= LOGIN =================

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final url = ApiConfig.uri("loginapp");

    try {
      final res = await http.post(
        url,
        headers: {
          "Accept": "application/json",
        },
        body: {
          "email": email,
          "password": password,
        },
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

  // ================= AI OUTFIT =================

  static Future<dynamic> getOutfitSuggestion(
    String token,
    String season,
    String occasion,
    String userId,
  ) async {
    final url = ApiConfig.uri(
      "outfit/suggest",
      query: {
        "season": season,
        "occasion": occasion,
        "user_id": userId,
      },
    );

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print("AI STATUS: ${res.statusCode}");
    print("AI BODY: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }

  // ================= IMPORTANT DATES =================

  static Future<dynamic> getImportantDates(
    String token,
    String userId,
  ) async {
    final url = ApiConfig.uri(
      "important-dates",
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

  static Future<dynamic> deleteImportantDate(
    String token,
    String id,
  ) async {
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

  static Future<dynamic> getTravelPlans(
    String token,
    String userId,
  ) async {
    final url = ApiConfig.uri(
      "travel-plans",
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

  static Future<dynamic> deleteTravelPlan(
    String token,
    String id,
  ) async {
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

  static Future<dynamic> getTravelItems(
    String token,
    String planId,
  ) async {
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

  static Future<dynamic> deleteTravelItem(
    String token,
    String id,
  ) async {
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

  static Future<dynamic> getImages(
    String token,
    String userId,
  ) async {
    final url = ApiConfig.uri(
      "images",
      query: {"user_id": userId},
    );

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

  static Future<dynamic> deleteImage(
    String token,
    String id,
  ) async {
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
        request.fields.addAll({
          "_method": "PUT",
          ...fields,
        });

        final bytes = await imageFile.readAsBytes();
        final fileName = imageFile.path.split('/').last;
        request.files.add(
          http.MultipartFile.fromBytes(
            "image",
            bytes,
            filename: fileName,
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
          body: {
            "_method": "PUT",
            ...fields,
          },
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

  // ================= INNER CIRCLE =================

  static Future<dynamic> getInnerCirclePosts(
    String token,
    String userId,
  ) async {
    final url = ApiConfig.uri(
      "inner-circle/posts",
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
        body: {
          "user_id": userId,
          "email": email,
        },
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
        body: {
          "code": code,
        },
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
        body: {
          "comment": comment,
        },
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
