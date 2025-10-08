// lib/screens/collab_request_store.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinpoint/globals.dart';

class CollobRequestStore extends StatelessWidget {
  final String storeId;

  const CollobRequestStore({Key? key, required this.storeId}) : super(key: key);

  Future<DocumentSnapshot<Map<String, dynamic>>> getStoreDetails() async {
    return await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();
  }

  Future<void> sendCollabRequest(BuildContext context, String receiverUid) async {
    final currentUid = currentUser?.uid ?? "";
    if (currentUid.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection("collabs")
          .doc(currentUid)
          .set({
            "shops": FieldValue.arrayUnion([receiverUid]),
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Collaboration request sent!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: getStoreDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                "Store not found.",
                style: TextStyle(fontSize: 18),
              ),
            ),
          );
        }

        final store = snapshot.data!.data()!;
        final name = store['shopName'] ?? store['name'] ?? 'Unnamed Store';
        final description = store['description'] ?? 'No description available.';
        final address = store['address'] ?? 'Address not available';
        final email = store['email'] ?? 'N/A';
        final phone = store['phone'] ?? 'N/A';
        final city = store['city'] ?? '';
        final district = store['district'] ?? '';
        final shopContact = store['shopContact'] ?? '';
        final lat = store['shopLocation']?['lat']?.toString() ?? '0.0';
        final lng = store['shopLocation']?['lng']?.toString() ?? '0.0';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A148C),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                Divider(color: Colors.grey.shade300),

                // Details List
                _infoTile(Icons.location_on, "$address, $district, $city"),
                _infoTile(Icons.email, email),
                _infoTile(Icons.phone, phone),
                if (shopContact.isNotEmpty)
                  _infoTile(Icons.contact_phone, shopContact),
                _infoTile(Icons.map, "Lat: $lat, Lng: $lng"),

                const SizedBox(height: 25),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            sendCollabRequest(context, store['uid']),
                        icon: const Icon(Icons.handshake_rounded, size: 20),
                        label: const Text(
                          "Send Request",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD1C4E9), // Light lavender
                          foregroundColor: const Color(0xFF4A148C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text("Cancel"),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4A148C)),
                          foregroundColor: const Color(0xFF4A148C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6A1B9A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
