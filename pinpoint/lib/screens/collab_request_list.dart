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

  final List<String> languages = ['en', 'es', 'fr', 'de', 'hi', 'ta'];

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
      final storesSnap = await firestore.collection('stores').get();
      final allStores =
          storesSnap.docs.map((e) => Shop.fromMap(e.data())).toList();

      final cityDoc = await firestore.collection('cities').doc(city).get();
      final nearbyUids = List<String>.from(cityDoc.data()?['shops'] ?? []);

      final collabDoc = await firestore.collection('collabs').doc(uid).get();
      final collabData = List<Map<String, dynamic>>.from(
        collabDoc.data()?['shops'] ?? [],
      );

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
          _actionButton("Cancel", Icons.cancel_outlined, Colors.red,
              () => _updateCollabStatus(shop.uid, 'denied_by_me')),
        ];
        break;
      case 'Incoming Request':
        actions = [
          _actionButton("Accept", Icons.check_circle_outline, Colors.green,
              () => _updateCollabStatus(shop.uid, 'accepted_by_me')),
          _actionButton("Deny", Icons.close_rounded, Colors.red,
              () => _updateCollabStatus(shop.uid, 'denied_by_me')),
        ];
        break;
      case 'Accepted':
        actions = [
          _actionButton("Remove", Icons.block_rounded, Colors.red,
              () => _updateCollabStatus(shop.uid, 'denied_by_me')),
        ];
        break;
      case 'Denied':
        actions = [
          _actionButton("Retry", Icons.refresh_rounded, Colors.orange,
              () => _updateCollabStatus(shop.uid, 'requested_out')),
        ];
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.purple.shade50,
            child: const Icon(Icons.storefront, color: Color(0xFF6A1B9A)),
          ),
          title: Text(
            shop.shopName.isNotEmpty ? shop.shopName : shop.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(shop.city, style: const TextStyle(color: Colors.grey)),
          trailing: Wrap(spacing: 4, children: actions),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: CollobRequestStore(storeId: shop.uid),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  Widget _buildStatusSection(String title, List<Shop> shops) {
    if (shops.isEmpty) return const SizedBox.shrink();

    final colorMap = {
      'Request Sent': Colors.orange.shade600,
      'Incoming Request': Colors.blue.shade600,
      'Accepted': Colors.green.shade600,
      'Denied': Colors.red.shade600,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorMap[title]!.withOpacity(0.1),
          child: Icon(Icons.folder_special, color: colorMap[title]),
        ),
        title: translateText(title),
        children: shops.map((shop) => _buildShopTile(shop, title)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        title: translateText("Collaboration Requests"),
        iconTheme: const IconThemeData(color: Color(0xFF4A148C)),
        actions: [
          DropdownButton<String>(
            value: selectedLang,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Color(0xFF4A148C)),
            dropdownColor: Colors.white,
            items: ['en', 'es', 'fr', 'de', 'hi', 'ta'].map((lang) {
              return DropdownMenuItem<String>(
                value: lang,
                child: Text(
                  lang.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => selectedLang = value);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...statusShops.entries
                      .map((entry) => _buildStatusSection(entry.key, entry.value))
                      .toList(),
                  const SizedBox(height: 25),
                  translateText("Available Nearby Shops"),
                  const SizedBox(height: 10),
                  if (nearbyShops.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: translateText("No nearby shops available."),
                    )
                  else
                    ...nearbyShops.map(
                      (shop) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEDE7F6),
                              child: Icon(Icons.store, color: Color(0xFF6A1B9A)),
                            ),
                            title: Text(shop.shopName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(shop.city,
                                style: const TextStyle(color: Colors.grey)),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD1C4E9),
                                foregroundColor: const Color(0xFF4A148C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 1.5,
                              ),
                              onPressed: () =>
                                  _updateCollabStatus(shop.uid, 'requested_out'),
                              icon: const Icon(Icons.add, size: 18),
                              label: translateText("Request"),
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
