import 'dart:convert';
import 'package:http/http.dart' as http;

class NokiaApiService {
  static const String baseUrl =
      "https://network-as-code.p-eu.rapidapi.com/congestion-insights/v0/query";

  static const String apiKey =
      "4793e5a172mshea504fb896d1b7ap18576djsncee7ac8ec291";

  static Future<List<dynamic>> getCongestionData(String phoneNumber) async {
    final body = {
      "device": {"phoneNumber": phoneNumber},
      "webhook": {
        "notificationUrl": "http://example.com/notify",
        "notificationAuthToken": "c8974e592f9fh683d4a3960714",
      },
      "subscriptionExpireTime": "2045-04-12T14:09:33+05:00",
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "x-rapidapi-host": "network-as-code.nokia.rapidapi.com",
        "x-rapidapi-key": apiKey,
      },
      body: jsonEncode(body),
    );

    print("API Response Status: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Failed to fetch congestion data: ${response.statusCode} ${response.body}",
      );
    }
  }
}
