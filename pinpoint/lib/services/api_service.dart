import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/footfall_data.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:8000'; // Android emulator (change to your IP for physical device)

  // Load local footfall data (unchanged)
  Future<List<FootfallData>> fetchFootfallData() async {
    final String response =
        await rootBundle.loadString('assets/mock_footfall.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => FootfallData.fromJson(json)).toList();
  }

  // Send geofence events to backend (which calls Nokia API)
  static Future<void> sendGeofenceEvent({
    required String geofenceId,
    required String event,
    required double lat,
    required double lon,
  }) async {
    final url = Uri.parse('$baseUrl/api/geofence/trigger');
    final payload = {
      'device_id': 'flutter_device_123', // later: real device token
      'geofence_id': geofenceId,
      'lat': lat,
      'lon': lon,
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('✅ Event sent successfully → ${response.body}');
      } else {
        print(
            '⚠️ Failed to send event [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      print('❌ Network error: $e');
    }
  }
}
