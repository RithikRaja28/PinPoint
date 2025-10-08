import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:pinpoint/user_model.dart';
import 'package:http/http.dart' as http;

// 🌍 Global Variables
String selectedLang = 'en';
final globalTranslator = GoogleTranslator();
UserModel? currentUser;

final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

// 🛰️ Backend API Endpoint
const String endpoint1 = "http://192.168.1.11:5000";

// 📍 Location Details
double? currentLat;
double? currentLong;
double? radius;
String? lastLocationTime;

/// 🌐 Fetch latest location from server
Future<void> findLocation() async {
  final url = Uri.parse('$endpoint1/api/geofence/location/retrieve');

  // ✅ Fallback to dummy number if user not logged in
  final phoneNumber = "+91${currentUser?.phone ?? '99999990422'}";

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "device": {"phoneNumber": "+99999990422"},
        "maxAge": 60, // Optional: restricts cached locations
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ Server Response: $data');

      final location = data['location'];
      if (location != null) {
        currentLat = (location['latitude'] as num?)?.toDouble();
        currentLong = (location['longitude'] as num?)?.toDouble();
        radius = (location['radius'] as num?)?.toDouble();
        lastLocationTime = location['lastLocationTime']?.toString();

        debugPrint(
          "📍 Location Retrieved:\n"
          "   Latitude: $currentLat\n"
          "   Longitude: $currentLong\n"
          "   Radius: $radius\n"
          "   Last Seen: $lastLocationTime",
        );
      } else {
        debugPrint("⚠️ No location data found in response.");
      }
    } else {
      debugPrint(
        '❌ Error ${response.statusCode}: ${response.reasonPhrase}\n'
        'Response body: ${response.body}',
      );
    }
  } catch (e, stack) {
    debugPrint('🚨 Exception in findLocation(): $e');
    debugPrint(stack.toString());
  }
}

// Navigator.pushReplacementNamed(context, '/dashboard');

//  FutureBuilder<String>(
//               future: translator
//                   .translate(textToTranslate, to: selectedLang)
//                   .then((value) => value.text),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Text(
//                     "Translating...",
//                     style: TextStyle(color: Colors.black54),
//                   );
//                 }
//                 if (snapshot.hasError) {
//                   return const Text(
//                     "Error during translation",
//                     style: TextStyle(color: Colors.red),
//                   );
//                 }
//                 return Text(
//                   snapshot.data ?? "",
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Colors.blueAccent,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 );
//               },
//             ),
