// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pinpoint/globals.dart';
// import 'collab_request_store.dart';

// class Shop {
//   final String uid;
//   final String name;
//   final String email;
//   final String phone;
//   final String address;
//   final String city;
//   final String district;
//   final String description;
//   final String shopName;
//   final double lat;
//   final double lng;

//   Shop({
//     required this.uid,
//     required this.name,
//     required this.email,
//     required this.phone,
//     required this.address,
//     required this.city,
//     required this.district,
//     required this.description,
//     required this.shopName,
//     required this.lat,
//     required this.lng,
//   });

//   factory Shop.fromMap(Map<String, dynamic> data) {
//     return Shop(
//       uid: data['uid'] ?? '',
//       name: data['name'] ?? '',
//       email: data['email'] ?? '',
//       phone: data['phone'] ?? '',
//       address: data['address'] ?? '',
//       city: data['city'] ?? '',
//       district: data['district'] ?? '',
//       description: data['description'] ?? '',
//       shopName: data['shopName'] ?? '',
//       lat: (data['shopLocation']?['lat'] ?? 0.0).toDouble(),
//       lng: (data['shopLocation']?['lng'] ?? 0.0).toDouble(),
//     );
//   }
// }

// class ColobRequestList extends StatefulWidget {
//   @override
//   State<ColobRequestList> createState() => _ColobRequestListState();
// }

// class _ColobRequestListState extends State<ColobRequestList> {
//   List<Shop> nearbyShops = [];
//   List<Shop> collabShops = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadShops();
//   }

//   Future<void> _loadShops() async {
//     try {
//       final city = currentUser?.city ?? '';
//       final uid = currentUser?.uid ?? '';

//       if (city.isEmpty || uid.isEmpty) {
//         setState(() => isLoading = false);
//         return;
//       }

//       final firestore = FirebaseFirestore.instance;

//       // Get nearby shop UIDs
//       final cityDoc = await firestore.collection('cities').doc(city).get();
//       final nearbyUids = List<String>.from(cityDoc.data()?['shops'] ?? []);

//       // Get collab shop UIDs
//       final collabDoc = await firestore.collection('collabs').doc(uid).get();
//       final collabUids = List<String>.from(collabDoc.data()?['shops'] ?? []);

//       // Fetch store details
//       final storesSnap = await firestore.collection('stores').get();
//       final allStores = storesSnap.docs
//           .map((e) => Shop.fromMap(e.data()))
//           .toList();

//       setState(() {
//         nearbyShops = allStores
//             .where((shop) => nearbyUids.contains(shop.uid) && shop.uid != uid)
//             .toList();
//         collabShops = allStores
//             .where((shop) => collabUids.contains(shop.uid) && shop.uid != uid)
//             .toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       print("Error loading shops: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   Widget _buildShopCard(Shop shop, BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => CollobRequestStore(storeId: shop.uid),
//           ),
//         );
//       },
//       child: Card(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         color: Colors.white,
//         elevation: 5,
//         child: ListTile(
//           leading: const Icon(Icons.store, color: Color(0xFF6A0DAD)),
//           title: Text(
//             shop.shopName.isNotEmpty ? shop.shopName : shop.name,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF6A0DAD),
//             ),
//           ),
//           subtitle: Text(shop.city, style: TextStyle(color: Colors.grey[700])),
//           trailing: const Icon(
//             Icons.arrow_forward_ios,
//             color: Color(0xFF6A0DAD),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF6A0DAD),
//       appBar: AppBar(
//         title: const Text("Nearby Stores"),
//         backgroundColor: const Color(0xFF6A0DAD),
//         elevation: 0,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator(color: Colors.white))
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Your Collaborations",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   if (collabShops.isEmpty)
//                     const Text(
//                       "No collaborations yet",
//                       style: TextStyle(color: Colors.white70),
//                     )
//                   else
//                     ...collabShops
//                         .map((shop) => _buildShopCard(shop, context))
//                         .toList(),
//                   const SizedBox(height: 20),
//                   const Text(
//                     "Nearby Shops",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   if (nearbyShops.isEmpty)
//                     const Text(
//                       "No nearby shops found",
//                       style: TextStyle(color: Colors.white70),
//                     )
//                   else
//                     ...nearbyShops
//                         .map((shop) => _buildShopCard(shop, context))
//                         .toList(),
//                 ],
//               ),
//             ),
//     );
//   }
// }

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
  const ColobRequestList({super.key});

  @override
  State<ColobRequestList> createState() => _ColobRequestListState();
}

class _ColobRequestListState extends State<ColobRequestList> {
  bool isLoading = true;
  Map<String, List<Shop>> statusShops = {
    'Request Sent': [],
    'Incoming Request': [],
    'Accepted': [],
    'Denied': [],
  };
  List<Shop> nearbyShops = [];

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

      // Load all shops from Firestore
      final storesSnap = await firestore.collection('stores').get();
      final allStores = storesSnap.docs
          .map((e) => Shop.fromMap(e.data()))
          .toList();

      // Load nearby shop UIDs
      final cityDoc = await firestore.collection('cities').doc(city).get();
      final nearbyUids = List<String>.from(cityDoc.data()?['shops'] ?? []);

      // Load collab data (maps with shop + status)
      final collabDoc = await firestore.collection('collabs').doc(uid).get();
      final collabData = List<Map<String, dynamic>>.from(
        collabDoc.data()?['shops'] ?? [],
      );

      // Group by status
      Map<String, List<Shop>> grouped = {
        'Request Sent': [],
        'Incoming Request': [],
        'Accepted': [],
        'Denied': [],
      };

      for (var collab in collabData) {
        final shopId = collab['shop'];
        final status = collab['status'];
        final shop = allStores.firstWhere(
          (s) => s.uid == shopId,
          orElse: () => Shop(
            uid: shopId,
            name: "Unknown",
            email: "",
            phone: "",
            address: "",
            city: "",
            district: "",
            description: "",
            shopName: "Unknown",
            lat: 0,
            lng: 0,
          ),
        );

        switch (status) {
          case 'requested_out':
            grouped['Request Sent']!.add(shop);
            break;
          case 'requested_in':
            grouped['Incoming Request']!.add(shop);
            break;
          case 'accepted_by_other':
          case 'accepted_by_me':
            grouped['Accepted']!.add(shop);
            break;
          case 'denied_by_other':
          case 'denied_by_me':
            grouped['Denied']!.add(shop);
            break;
        }
      }

      // Filter nearby shops (excluding those already in collabs)
      final collabUids = collabData.map((e) => e['shop']).toSet();
      final nearbyFiltered = allStores
          .where(
            (shop) =>
                nearbyUids.contains(shop.uid) && !collabUids.contains(shop.uid),
          )
          .toList();

      setState(() {
        statusShops = grouped;
        nearbyShops = nearbyFiltered;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading shops: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateCollabStatus(String shopId, String newStatus) async {
    final uid = currentUser?.uid ?? '';
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('collabs').doc(uid);

    final doc = await docRef.get();
    List<Map<String, dynamic>> shops = List<Map<String, dynamic>>.from(
      doc.data()?['shops'] ?? [],
    );
    final index = shops.indexWhere((s) => s['shop'] == shopId);

    if (index != -1) {
      shops[index]['status'] = newStatus;
    } else {
      shops.add({'shop': shopId, 'status': newStatus});
    }

    await docRef.set({'shops': shops});
    _loadShops();
  }

  Widget _buildShopTile(Shop shop, String status) {
    List<Widget> actions = [];

    switch (status) {
      case 'Request Sent':
        actions = [
          _actionButton(
            "Cancel",
            Icons.cancel,
            Colors.red,
            () => _updateCollabStatus(shop.uid, 'denied_by_me'),
          ),
          _actionButton(
            "Request Again",
            Icons.refresh,
            Colors.orange,
            () => _updateCollabStatus(shop.uid, 'requested_out'),
          ),
        ];
        break;
      case 'Incoming Request':
        actions = [
          _actionButton(
            "Accept",
            Icons.check_circle,
            Colors.green,
            () => _updateCollabStatus(shop.uid, 'accepted_by_me'),
          ),
          _actionButton(
            "Deny",
            Icons.close,
            Colors.red,
            () => _updateCollabStatus(shop.uid, 'denied_by_me'),
          ),
        ];
        break;
      case 'Accepted':
        actions = [
          _actionButton(
            "Cancel",
            Icons.cancel,
            Colors.red,
            () => _updateCollabStatus(shop.uid, 'denied_by_me'),
          ),
        ];
        break;
      case 'Denied':
        actions = [
          _actionButton(
            "Request Again",
            Icons.refresh,
            Colors.orange,
            () => _updateCollabStatus(shop.uid, 'requested_out'),
          ),
        ];
        break;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: const Icon(Icons.store, color: Color(0xFF6A0DAD)),
        title: Text(shop.shopName.isNotEmpty ? shop.shopName : shop.name),
        subtitle: Text(shop.city),
        trailing: Wrap(spacing: 6, children: actions),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CollobRequestStore(storeId: shop.uid),
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: label,
      onPressed: onPressed,
    );
  }

  Widget _buildStatusSection(String title, List<Shop> shops) {
    if (shops.isEmpty) return const SizedBox.shrink();

    final colorMap = {
      'Request Sent': Colors.orange,
      'Incoming Request': Colors.blueAccent,
      'Accepted': Colors.green,
      'Denied': Colors.redAccent,
    };

    return Card(
      color: colorMap[title]?.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            color: colorMap[title],
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: shops.map((shop) => _buildShopTile(shop, title)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text("Collaboration Requests"),
        backgroundColor: const Color(0xFF6A0DAD),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A0DAD)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...statusShops.entries
                      .map(
                        (entry) => _buildStatusSection(entry.key, entry.value),
                      )
                      .toList(),
                  const SizedBox(height: 20),
                  const Text(
                    "Available Nearby Shops",
                    style: TextStyle(
                      color: Color(0xFF6A0DAD),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (nearbyShops.isEmpty)
                    const Text("No nearby shops available.")
                  else
                    ...nearbyShops.map(
                      (shop) => Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(
                            Icons.store,
                            color: Color(0xFF6A0DAD),
                          ),
                          title: Text(shop.shopName),
                          subtitle: Text(shop.city),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A0DAD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () =>
                                _updateCollabStatus(shop.uid, 'requested_out'),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "Request",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
