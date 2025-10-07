import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/footfall_data.dart';
import '../models/post_model.dart';

class ApiService {
  // 🧠 Use 10.0.2.2 for Android emulator, or replace with your system IP for physical device
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ---------------------------------------------------------------------------
  // 📊 FOOTFALL DATA (Mock Analytics)
  // ---------------------------------------------------------------------------
  Future<List<FootfallData>> fetchFootfallData() async {
    final String response =
        await rootBundle.loadString('assets/mock_footfall.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => FootfallData.fromJson(json)).toList();
  }

  // ---------------------------------------------------------------------------
  // 📍 GEOFENCE TRIGGER (Send Nokia events)
  // ---------------------------------------------------------------------------
  static Future<void> sendGeofenceEvent({
    required String geofenceId,
    required String event,
    required double lat,
    required double lon,
  }) async {
    final url = Uri.parse('$baseUrl/geofence/trigger');
    final payload = {
      'device_id': 'flutter_device_123', // TODO: replace with actual user/device ID
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
        print('✅ Geofence event sent → ${response.body}');
      } else {
        print(
            '⚠️ Geofence event failed [${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      print('❌ Network error sending geofence event: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 💬 COMMUNITY FEATURE (Social Posts / Feedback)
  // ---------------------------------------------------------------------------

  // 🧭 Fetch nearby posts (based on user location)
  static Future<List<Post>> fetchNearbyPosts(double lat, double lon) async {
    final url = Uri.parse('$baseUrl/community/nearby');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lat': lat, 'lon': lon, 'radius': 2000}),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Post.fromJson(e)).toList();
      } else {
        print('⚠️ Failed to fetch nearby posts: ${res.body}');
        return [];
      }
    } catch (e) {
      print('❌ Network error fetching posts: $e');
      return [];
    }
  }

  // 📝 Create a new community post
  static Future<bool> createPost({
    required int userId,
    required int shopId,
    required String content,
    double? rating,
    String? imageUrl,
    required double lat,
    required double lon,
  }) async {
    final url = Uri.parse('$baseUrl/community/post');
    final payload = {
      'user_id': userId,
      'shop_id': shopId,
      'content': content,
      'rating': rating,
      'image_url': imageUrl,
      'lat': lat,
      'lon': lon,
    };

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 201) {
        print('✅ Post created successfully');
        return true;
      } else {
        print('⚠️ Failed to create post: ${res.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating post: $e');
      return false;
    }
  }

  // 🏪 Fetch all posts for a specific shop
  static Future<List<Post>> fetchShopPosts(int shopId) async {
    final url = Uri.parse('$baseUrl/community/shop/$shopId');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Post.fromJson(e)).toList();
      } else {
        print('⚠️ Failed to fetch shop posts: ${res.body}');
        return [];
      }
    } catch (e) {
      print('❌ Network error fetching shop posts: $e');
      return [];
    }
  }
}
