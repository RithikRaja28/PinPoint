import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/congestion_service.dart';
import 'dart:math';

class HeatmapOverlay extends StatefulWidget {
  final List<String> phoneNumbers;

  const HeatmapOverlay({super.key, required this.phoneNumbers});

  @override
  State<HeatmapOverlay> createState() => _HeatmapOverlayState();
}

class _HeatmapOverlayState extends State<HeatmapOverlay> {
  LatLng? mapCenter;
  Set<Circle> circles = {};
  bool loading = true;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initHeatmap();
  }

  Future<void> _initHeatmap() async {
    try {
      Set<Circle> newCircles = {};
      bool firstDevice = true;

      for (String phone in widget.phoneNumbers) {
        // 1️⃣ Get current location
        final center = await LocationService.getCurrentLocation(phone);
        if (firstDevice) {
          mapCenter = center;
          firstDevice = false;
        }

        // 2️⃣ Get congestion data
        final congestionData = await CongestionService.getCongestion(phone);

        // 3️⃣ Spread circles around the device location
        for (var record in congestionData) {
          double latOffset = (_random.nextDouble() - 0.5) * 0.0015;
          double lngOffset = (_random.nextDouble() - 0.5) * 0.0015;
          final lat = center.latitude + latOffset;
          final lng = center.longitude + lngOffset;

          String level = record['congestionLevel'] ?? "Low";
          int confidence = record['confidenceLevel'] ?? 100;

          Color fillColor;
          switch (level) {
            case "High":
              fillColor = Colors.red.withOpacity(confidence / 100);
              break;
            case "Medium":
              fillColor = Colors.orange.withOpacity(confidence / 100);
              break;
            default:
              fillColor = Colors.green.withOpacity(confidence / 100);
          }

          print(
            "Adding Circle: Phone=$phone, Lat=$lat, Lng=$lng, Level=$level, Confidence=$confidence",
          );

          newCircles.add(
            Circle(
              circleId: CircleId("$phone-$lat-$lng"),
              center: LatLng(lat, lng),
              radius: 50 + confidence.toDouble(),
              fillColor: fillColor,
              strokeColor: Colors.black.withOpacity(0.1),
              strokeWidth: 1,
            ),
          );
        }

      }

      setState(() {
        circles = newCircles;
        loading = false;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || mapCenter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: mapCenter!, zoom: 15),
      circles: circles,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
