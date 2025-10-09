import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../globals.dart';

class LocationSimulatorScreen extends StatefulWidget {
  const LocationSimulatorScreen({super.key});

  @override
  State<LocationSimulatorScreen> createState() =>
      _LocationSimulatorScreenState();
}

class _LocationSimulatorScreenState extends State<LocationSimulatorScreen> {
  late double latitude;
  late double longitude;
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    // Use global variables as initial location
    latitude = currentLat ?? 28.5552;
    longitude = currentLong ?? 77.0482;
  }

  // Move location by meters (positive = north, negative = south)
  void moveLocation(double distanceInMeters) {
    double deltaLat = distanceInMeters / 111000; // 1 degree ~ 111km
    setState(() {
      latitude += deltaLat;
      currentLat = latitude;
      currentLong = longitude;
    });

    mapController.animateCamera(
      CameraUpdate.newLatLng(LatLng(latitude, longitude)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Location Simulator"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Google Map Section
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("simulatedLocation"),
                    position: LatLng(latitude, longitude),
                    infoWindow: const InfoWindow(title: "Simulated Location"),
                  ),
                },
                onMapCreated: (controller) => mapController = controller,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
              ),
            ),

            // Location Details & Buttons
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Text(
                        "Latitude: ${latitude.toStringAsFixed(6)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Text(
                        "Longitude: ${longitude.toStringAsFixed(6)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => moveLocation(3000),
                        icon: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Move Forward 3 km",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => moveLocation(-1000),
                        icon: const Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Move Backward 1 km",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
