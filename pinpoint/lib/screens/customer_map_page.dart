import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomerMapPage extends StatefulWidget {
  const CustomerMapPage({super.key});

  @override
  State<CustomerMapPage> createState() => _CustomerMapPageState();
}

class _CustomerMapPageState extends State<CustomerMapPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(28.6139, 77.2090); // default Delhi
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadShops();
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Please enable location services");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg: "Location permissions are permanently denied",
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _initialPosition = LatLng(pos.latitude, pos.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId("user_location"),
          position: _initialPosition,
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      _loading = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _initialPosition, zoom: 14),
      ),
    );
  }

  // Load shops from Firebase
  Future<void> _loadShops() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['shopLocation'] != null) {
        final lat = data['shopLocation']['lat'];
        final lng = data['shopLocation']['Ing'];
        final shopName = data['shopName'] ?? "Shop";

        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: shopName,
                snippet: data['description'] ?? "",
                onTap: () {
                  _showShopDialog(shopName, data);
                },
              ),
            ),
          );
        });
      }
    }
  }

  // Dialog for shop details
  void _showShopDialog(String shopName, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.deepPurple[50],
        title: Text(
          shopName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Description: ${data['description'] ?? 'N/A'}"),
            const SizedBox(height: 8),
            Text("City: ${data['city'] ?? 'N/A'}"),
            Text("Phone: ${data['phone'] ?? 'N/A'}"),
            Text("Address: ${data['address'] ?? 'N/A'}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Shops"),
        centerTitle: true,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (controller) => _mapController = controller,
            ),
    );
  }
}
