// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class CollobRequestStore extends StatelessWidget {
//   final String storeId;

//   const CollobRequestStore({Key? key, required this.storeId}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF6A0DAD),
//       appBar: AppBar(
//         title: Text("Store Details"),
//         backgroundColor: Color(0xFF6A0DAD),
//         elevation: 0,
//       ),
//       body: FutureBuilder<DocumentSnapshot>(
//         future: FirebaseFirestore.instance
//             .collection('stores')
//             .doc(storeId)
//             .get(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return Center(
//               child: CircularProgressIndicator(color: Colors.white),
//             );
//           }

//           var store = snapshot.data!;
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               color: Colors.white,
//               elevation: 8,
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       store['name'] ?? 'Store Name',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF6A0DAD),
//                       ),
//                     ),
//                     SizedBox(height: 10),
//                     // Text(
//                     //   store['address'] ?? 'Address',
//                     //   style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//                     // ),
//                     SizedBox(height: 20),
//                     // Text(
//                     //   store['description'] ?? 'No description available.',
//                     //   style: TextStyle(fontSize: 16, color: Colors.grey[800]),
//                     // ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

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

  Future<void> sendCollabRequest(
    BuildContext context,
    String receiverUid,
  ) async {
    final currentUid = currentUser?.uid ?? "";
    if (currentUid.isEmpty) return;

    try {
      // Add this shop UID to user's collab list
      await FirebaseFirestore.instance
          .collection("collabs")
          .doc(currentUid)
          .set({
            "shops": FieldValue.arrayUnion([receiverUid]),
          }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Collaboration request sent!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error sending request: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A0DAD),
      appBar: AppBar(
        title: const Text("Store Details"),
        backgroundColor: const Color(0xFF6A0DAD),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getStoreDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Store not found.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final store = snapshot.data!.data()!;
          final name = store['shopName'] ?? store['name'] ?? 'Unnamed Store';
          final description =
              store['description'] ?? 'No description available.';
          final address = store['address'] ?? 'Address not available';
          final email = store['email'] ?? 'N/A';
          final phone = store['phone'] ?? 'N/A';
          final city = store['city'] ?? '';
          final district = store['district'] ?? '';
          final shopContact = store['shopContact'] ?? '';
          final lat = store['shopLocation']?['lat']?.toString() ?? '0.0';
          final lng = store['shopLocation']?['lng']?.toString() ?? '0.0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Shop Name ---
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A0DAD),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey[400]),
                    const SizedBox(height: 10),

                    // --- Description ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description, color: Color(0xFF6A0DAD)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- Address ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF6A0DAD)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "$address, $district, $city",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- Contact Info ---
                    Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFF6A0DAD)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Color(0xFF6A0DAD)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    if (shopContact.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.contact_mail,
                            color: Color(0xFF6A0DAD),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              shopContact,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 15),

                    // --- Map coordinates ---
                    Row(
                      children: [
                        const Icon(Icons.map, color: Color(0xFF6A0DAD)),
                        const SizedBox(width: 10),
                        Text(
                          "Lat: $lat, Lng: $lng",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // --- Collaboration Button ---
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            sendCollabRequest(context, store['uid']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A0DAD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.handshake, color: Colors.white),
                        label: const Text(
                          "Send Collaboration Request",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
