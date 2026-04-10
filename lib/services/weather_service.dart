import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {

  // 🔑 Replace with your real key
  static const String apiKey = "070387fd7f1238c63b4fbdae947a1361";

  Future<double> getTemperature(
      double lat,
      double lon,
      ) async {

    final url =
        "https://api.openweathermap.org/data/2.5/weather"
        "?lat=$lat&lon=$lon"
        "&appid=$apiKey"
        "&units=metric";

    try {

      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {

        final data = jsonDecode(res.body);

        return data['main']['temp'].toDouble();
      }

    } catch (e) {
      print("WEATHER ERROR: $e");
    }

    // fallback
    return 25.0;
  }
}
