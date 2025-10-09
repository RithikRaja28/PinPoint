import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinpoint/user_model.dart';
import 'package:http/http.dart' as http;

/// 🌍 Global Variables
String selectedLang = 'en';
final globalTranslator = GoogleTranslator();
UserModel? currentUser;
String? FCM_TOKEN;
final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
// 🛰️ Backend API Endpoint
const String endpoint1 = "http://10.82.69.61:5000";
// 📍 Location Details
double? currentLat;
double? currentLong;
double? radius;
String? lastLocationTime;

Future<void> updateFcmToken(String? fcmToken, String? phone) async {
  if (phone != null &&
      phone.isNotEmpty &&
      fcmToken != null &&
      fcmToken.isNotEmpty) {
    try {
      await FirebaseFirestore.instance.collection("fcm_map").doc(phone).set({
        "token": fcmToken,
      }, SetOptions(merge: true)); // ✅ Updates if exists
      print("✅ FCM token updated for $phone");
    } catch (e) {
      print("❌ Error updating FCM token for $phone: $e");
    }
  } else {
    print("⚠️ Missing phone or FCM token. Skipping Firestore update.");
  }
}

/// 🌐 Fetch latest location from server
Future<void> findLocation() async {
  print(
    "entered ======================================================================",
  );
  final url = Uri.parse('$endpoint1/api/geofence/location/retrieve');
  final phoneNumber = "+${currentUser?.phone ?? '91123456666'}";

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "device": {"phoneNumber": phoneNumber},
        "maxAge": 60,
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

/// 🌐 Fetch latest location from server
Future<void> findConnectivityStatus() async {
  final url = Uri.parse('$endpoint1/api/geofence/location/cstatus');

  // ✅ Fallback to dummy number if user not logged in
  final phoneNumber = "+91${currentUser?.phone ?? '+36719991000'}";

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"phoneNumber": phoneNumber}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('✅ Server Response: $data');

      final status = data["data"];
      if (status == "connected ") {
        // #trigger push notification
      } else if (status == "sms") {
        // trigger sms
      } else {
        // trigger nothing
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

  /// 🗣️ Universal translation widget
  ///
  /// Use inside UI as:
  /// ```dart
  /// translateText("Hello, World!")
  /// ```
  ///
}

Widget translateText(String text) {
  return FutureBuilder<String>(
    future: globalTranslator
        .translate(text, to: selectedLang)
        .then((value) => value.text),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Text(
          "Translating...",
          style: TextStyle(color: Colors.black54),
        );
      }
      if (snapshot.hasError) {
        return const Text(
          "Error during translation",
          style: TextStyle(color: Colors.red),
        );
      }
      return Text(
        snapshot.data ?? text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.blueAccent,
          fontWeight: FontWeight.w600,
        ),
      );
    },
  );
}
