import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinpoint/screens/customers/customer_profile.dart';
import 'package:pinpoint/user_model.dart';
import 'package:pinpoint/globals.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
 
import 'package:pinpoint/screens/business/business_profile.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  int _currentIndex = 0;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(28.6139, 77.2090); // Default Delhi
  bool _loadingMap = true;

  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _getCurrentLocation();
    await _loadShops();
  }

  // ------------------- Location -------------------
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Enable location services!");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        setState(() {
          _initialPosition = LatLng(lastPos.latitude, lastPos.longitude);
        });
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = LatLng(pos.latitude, pos.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId("user_location"),
            position: _initialPosition,
            infoWindow: const InfoWindow(title: "You are here"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
        _loadingMap = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _initialPosition, zoom: 14),
          ),
        );
      }
    } catch (e) {
      setState(() => _loadingMap = false);
    }
  }

  // ------------------- Load Shops from Firebase -------------------
  Future<void> _loadShops() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stores')
          .get();

      final newMarkers = <Marker>{};
      final shopsData = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['shopLocation'] == null) continue;
        final lat = data['shopLocation']['lat'];
        final lng = data['shopLocation']['lng'];
        if (lat == null || lng == null) continue;

        newMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: data['shopName'] ?? "Shop",
              snippet: data['description'] ?? "",
              onTap: () => _showShopDialog(data['shopName'] ?? "Shop", data),
            ),
          ),
        );

        shopsData.add({
          "id": doc.id,
          "name": data['shopName'] ?? "Shop",
          "description": data['description'] ?? "",
          "city": data['city'] ?? "",
          "phone": data['phone'] ?? "",
          "lat": lat,
          "lng": lng,
        });
      }

      setState(() {
        _markers.addAll(newMarkers);
        _shops = shopsData;
        _loadingMap = false;
      });
    } catch (e) {
      setState(() => _loadingMap = false);
    }
  }

  void _showShopDialog(String shopName, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shopName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            Text("Description: ${data['description'] ?? 'N/A'}"),
            Text("City: ${data['city'] ?? 'N/A'}"),
            Text("Phone: ${data['phone'] ?? 'N/A'}"),
            Text("Address: ${data['address'] ?? 'N/A'}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 25,
                ),
              ),
              child: const Text("Close", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- Profile Section -------------------
  Widget _buildProfile() {
    if (currentUser == null) {
      return const Center(child: Text("User not found"));
    }
    return const CustomerProfile();
  }


  // ------------------- Map Section -------------------
  Widget _mapSection() {
    return _loadingMap
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                key: const ValueKey("shop_map"),
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
              DraggableScrollableSheet(
                initialChildSize: 0.12,
                minChildSize: 0.12,
                maxChildSize: 0.4,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _shops.length,
                      itemBuilder: (context, index) {
                        final shop = _shops[index];
                        return GestureDetector(
                          onTap: () {
                            LatLng shopPos = LatLng(shop['lat'], shop['lng']);
                            _mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(target: shopPos, zoom: 16),
                              ),
                            );
                            _showShopDialog(shop['name'], shop);
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    shop['description'],
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "City: ${shop['city']}, Phone: ${shop['phone']}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _sections = [_buildProfile(), _mapSection()];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? "Profile" : "Explore Shops",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.purple[400],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _sections[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.purple[400],
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 5,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Shops Map"),
        ],
      ),
    );
  }
}
