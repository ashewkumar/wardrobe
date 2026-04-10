import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {

  static Future<String?> login(String email, String password) async {

    try {

      final response = await http.post(
        ApiConfig.uri("loginapp"),

        // 🔴 IMPORTANT HEADERS
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },

        body: {
          "email": email,
          "password": password,
        },
      );

      // 🔍 DEBUG
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {

        final Map<String, dynamic> data =
            jsonDecode(response.body);

        // ✅ EXACT MATCH WITH YOUR BACKEND
        if (data['status'] == true &&
            data['token'] != null &&
            data['token'].toString().isNotEmpty) {

          return data['token'].toString();
        }
      }

    } catch (e) {
      print("LOGIN ERROR: $e");
    }

    return null;
  }
}
