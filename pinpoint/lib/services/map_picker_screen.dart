import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _selectedLatLng = const LatLng(13.0827, 80.2707); // default Chennai

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Shop Location"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng,
              zoom: 14,
            ),
            onTap: (pos) => setState(() => _selectedLatLng = pos),
            markers: {
              Marker(
                markerId: const MarkerId("shop"),
                position: _selectedLatLng,
              ),
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Confirm Location",
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.pop(context, _selectedLatLng);
              },
            ),
          ),
        ],
      ),
    );
  }
}
