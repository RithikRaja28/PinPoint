import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinpoint/globals.dart';
import 'collab_request_store.dart';

class Shop {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String district;
  final String description;
  final String shopName;
  final double lat;
  final double lng;

  Shop({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.district,
    required this.description,
    required this.shopName,
    required this.lat,
    required this.lng,
  });

  factory Shop.fromMap(Map<String, dynamic> data) {
    return Shop(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      description: data['description'] ?? '',
      shopName: data['shopName'] ?? '',
      lat: (data['shopLocation']?['lat'] ?? 0.0).toDouble(),
      lng: (data['shopLocation']?['lng'] ?? 0.0).toDouble(),
    );
  }
}

class ColobRequestList extends StatefulWidget {
  @override
  State<ColobRequestList> createState() => _ColobRequestListState();
}

class _ColobRequestListState extends State<ColobRequestList> {
  List<Shop> nearbyShops = [];
  List<Shop> collabShops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final city = currentUser?.city ?? '';
      final uid = currentUser?.uid ?? '';

      if (city.isEmpty || uid.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // Get nearby shop UIDs
      final cityDoc = await firestore.collection('cities').doc(city).get();
      final nearbyUids = List<String>.from(cityDoc.data()?['shops'] ?? []);

      // Get collab shop UIDs
      final collabDoc = await firestore.collection('collabs').doc(uid).get();
      final collabUids = List<String>.from(collabDoc.data()?['shops'] ?? []);

      // Fetch store details
      final storesSnap = await firestore.collection('stores').get();
      final allStores = storesSnap.docs
          .map((e) => Shop.fromMap(e.data()))
          .toList();

      setState(() {
        nearbyShops = allStores
            .where((shop) => nearbyUids.contains(shop.uid) && shop.uid != uid)
            .toList();
        collabShops = allStores
            .where((shop) => collabUids.contains(shop.uid) && shop.uid != uid)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error loading shops: $e");
      setState(() => isLoading = false);
    }
  }

  Widget _buildShopCard(Shop shop, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollobRequestStore(storeId: shop.uid),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.white,
        elevation: 5,
        child: ListTile(
          leading: const Icon(Icons.store, color: Color(0xFF6A0DAD)),
          title: Text(
            shop.shopName.isNotEmpty ? shop.shopName : shop.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A0DAD),
            ),
          ),
          subtitle: Text(shop.city, style: TextStyle(color: Colors.grey[700])),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF6A0DAD),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A0DAD),
      appBar: AppBar(
        title: const Text("Nearby Stores"),
        backgroundColor: const Color(0xFF6A0DAD),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your Collaborations",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (collabShops.isEmpty)
                    const Text(
                      "No collaborations yet",
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    ...collabShops
                        .map((shop) => _buildShopCard(shop, context))
                        .toList(),
                  const SizedBox(height: 20),
                  const Text(
                    "Nearby Shops",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (nearbyShops.isEmpty)
                    const Text(
                      "No nearby shops found",
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    ...nearbyShops
                        .map((shop) => _buildShopCard(shop, context))
                        .toList(),
                ],
              ),
            ),
    );
  }
}
