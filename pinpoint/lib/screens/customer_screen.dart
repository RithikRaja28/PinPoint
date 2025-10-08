import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinpoint/screens/customers/customer_profile.dart';
import 'package:pinpoint/user_model.dart';
import 'package:pinpoint/globals.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
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
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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

  // ------------------- Load Shops -------------------
  Future<void> _loadShops() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('stores').get();

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

  // ------------------- Shop Info Bottom Sheet -------------------
  void _showShopDialog(String shopName, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront, color: Colors.deepPurple, size: 28),
                const SizedBox(width: 8),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1.2, height: 30),
            _shopDetailRow(Icons.info_outline, "Description", data['description']),
            _shopDetailRow(Icons.location_city_rounded, "City", data['city']),
            _shopDetailRow(Icons.call, "Phone", data['phone']),
            _shopDetailRow(Icons.place, "Address", data['address']),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text("Close"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopDetailRow(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple[400], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title: ${value ?? 'N/A'}",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
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
        ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
        : Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapType: MapType.normal,
                onMapCreated: (controller) => _mapController = controller,
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.12,
                minChildSize: 0.12,
                maxChildSize: 0.45,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 45,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: const [
                              Icon(Icons.storefront_outlined,
                                  color: Colors.deepPurple, size: 22),
                              SizedBox(width: 8),
                              Text(
                                "Nearby Shops",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
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
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  shadowColor: Colors.deepPurple.withOpacity(0.3),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.deepPurple[100],
                                      child: const Icon(Icons.store, color: Colors.deepPurple),
                                    ),
                                    title: Text(
                                      shop['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    subtitle: Text(
                                      shop['description'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.location_on, color: Colors.purple),
                                      onPressed: () {
                                        LatLng shopPos = LatLng(shop['lat'], shop['lng']);
                                        _mapController?.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(target: shopPos, zoom: 16),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentIndex == 0 ? Icons.person_pin_circle : Icons.explore,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0 ? "My Profile" : "Explore Shops",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _sections[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person, color: Colors.deepPurple),
              label: "Profile",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map, color: Colors.deepPurple),
              label: "Shops Map",
            ),
          ],
        ),
      ),
    );
  }
}
