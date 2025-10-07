import 'package:http/http.dart' as http;
import 'dart:convert';

class CongestionService {
  static const String rapidApiKey =
      "4793e5a172mshea504fb896d1b7ap18576djsncee7ac8ec291";

  /// Fetch congestion data for a device
  static Future<List<dynamic>> getCongestion(String phoneNumber) async {
    final url = Uri.parse(
      "https://network-as-code.p-eu.rapidapi.com/congestion-insights/v0/query",
    );

    final body = {
      "device": {"phoneNumber": phoneNumber},
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-rapidapi-host": "network-as-code.nokia.rapidapi.com",
        "x-rapidapi-key": rapidApiKey,
      },
      body: jsonEncode(body),
    );

    print("Congestion API Status: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Fetched ${data.length} congestion records");
      return data;
    } else {
      throw Exception("Failed to fetch congestion data: ${response.body}");
    }
  }
}
