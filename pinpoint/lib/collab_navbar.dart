// collab_navbar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:pinpoint/screens/collab_request_list.dart';
import 'package:pinpoint/screens/community_feed_screen.dart';
import 'package:pinpoint/screens/customer_screen.dart';
import 'package:pinpoint/screens/ai_concierge_screen.dart'; // ✅ Import the new screen
import 'package:pinpoint/globals.dart';
import 'package:pinpoint/user_model.dart';

class CollabNavBar extends StatefulWidget {
  const CollabNavBar({super.key});

  @override
  State<CollabNavBar> createState() => _CollabNavBarState();
}

class _CollabNavBarState extends State<CollabNavBar> {
  int _selectedIndex = 0;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(28.6139, 77.2090);
  bool _loadingMap = true;
  List<Map<String, dynamic>> _shops = [];
  bool _shopsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _getCurrentLocation();
    await _loadShops();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Enable location services!");
        setState(() => _loadingMap = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loadingMap = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingMap = false);
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _initialPosition = LatLng(pos.latitude, pos.longitude);

      _markers.removeWhere((m) => m.markerId.value == "user_location");
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

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _initialPosition, zoom: 14),
          ),
        );
      }

      setState(() {
        _loadingMap = false;
      });
    } catch (e) {
      setState(() => _loadingMap = false);
    }
  }

  Future<void> _loadShops() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('stores').get();

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
          "address": data['address'] ?? "",
          "lat": lat,
          "lng": lng,
        });
      }

      setState(() {
        _markers.addAll(newMarkers);
        _shops = shopsData;
        _shopsLoaded = true;
        _loadingMap = false;
      });
    } catch (e) {
      setState(() {
        _shopsLoaded = false;
        _loadingMap = false;
      });
    }
  }

  void _showShopDialog(String shopName, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              shopName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.deepPurple.shade200, thickness: 1.2),
            const SizedBox(height: 10),
            _infoRow("📝 Description", data['description'] ?? 'N/A'),
            _infoRow("🏙 City", data['city'] ?? 'N/A'),
            _infoRow("📞 Phone", data['phone'] ?? 'N/A'),
            _infoRow("📍 Address", data['address'] ?? 'N/A'),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text("Close", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1C4E9),
                foregroundColor: Colors.deepPurple.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapSection() {
    if (_loadingMap) {
      return const Center(child: CircularProgressIndicator());
    }

    final mapKey = ValueKey(
        'shop_map_${_initialPosition.latitude}_${_initialPosition.longitude}');

    return Stack(
      children: [
        GoogleMap(
          key: mapKey,
          initialCameraPosition:
              CameraPosition(target: _initialPosition, zoom: 14),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            _mapController = controller;
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                  CameraPosition(target: _initialPosition, zoom: 14)),
            );
            setState(() {});
          },
        ),
      ],
    );
  }

  NavigationDestination _buildNavItem(
      IconData icon, IconData selectedIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return NavigationDestination(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? const Color(0xFF4B00C8) : Colors.transparent),
        child: Icon(isSelected ? selectedIcon : icon,
            color: Colors.white, size: isSelected ? 28 : 24),
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = currentUser;

    final pages = [
      ColobRequestList(),
      const CommunityFeedScreen(),
      const CustomerPage(),
      _mapSection(),
      const AIConciergeScreen(), // ✅ NEW PAGE
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A00F8), Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: const [
                    Icon(Icons.group, color: Colors.white, size: 28),
                    SizedBox(width: 6),
                    Text("PinPoint",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                  ]),
                  Row(children: [
                    if (user != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 2),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: "Logout",
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        currentUser = null;
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (r) => false);
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6A00F8), Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6A00F8).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              labelTextStyle:
                  MaterialStateProperty.resolveWith<TextStyle>((states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12);
                }
                return const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12);
              }),
            ),
            child: NavigationBar(
              height: 65,
              backgroundColor: Colors.transparent,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) {
                setState(() {
                  _selectedIndex = i;
                  if (_selectedIndex == 3 && !_shopsLoaded) {
                    _initMap();
                  }
                });
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                _buildNavItem(Icons.store_mall_directory_outlined, Icons.store,
                    "Stores", 0),
                _buildNavItem(Icons.people_outline, Icons.people, "Community", 1),
                _buildNavItem(
                    Icons.person_outline, Icons.person, "Customer", 2),
                _buildNavItem(Icons.map_outlined, Icons.map, "Show Map", 3),
                _buildNavItem(Icons.psychology_outlined, Icons.psychology,
                    "AI Assistant", 4), // ✅ NEW NAV ITEM
              ],
            ),
          ),
        ),
      ),
    );
  }
}
