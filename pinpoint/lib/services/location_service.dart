import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static const String rapidApiKey =
      "4793e5a172mshea504fb896d1b7ap18576djsncee7ac8ec291";

  /// Get current location of the device via Nokia API
  static Future<LatLng> getCurrentLocation(String phoneNumber) async {
    final url = Uri.parse(
      "https://network-as-code.p-eu.rapidapi.com/location-retrieval/v0/retrieve",
    );

    final body = {
      "device": {"phoneNumber": phoneNumber},
      "maxAge": 60,
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

    print("API Response Status: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final lat = data['area']['center']['latitude'];
      final lng = data['area']['center']['longitude'];
      print("Current Location: LatLng($lat, $lng)");
      return LatLng(lat, lng);
    } else {
      throw Exception("Failed to fetch location: ${response.body}");
    }
  }
}
