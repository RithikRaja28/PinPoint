import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinpoint/globals.dart';
import 'collob_request_store.dart';

class ColobRequestList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6A0DAD), // Match uploaded theme
      appBar: AppBar(
        title: Text("Nearby Stores"),
        backgroundColor: Color(0xFF6A0DAD),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stores').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // Filter out current user's store
          final stores = snapshot.data!.docs
              .where((doc) => doc.id != currentUser?.uid)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView.builder(
              itemCount: stores.length,
              itemBuilder: (context, index) {
                var store = stores[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollobRequestStore(storeId: store.id),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    color: Colors.white,
                    elevation: 5,
                    child: ListTile(
                      leading: Icon(Icons.store, color: Color(0xFF6A0DAD)),
                      title: Text(
                        store['name'] ?? 'Store Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A0DAD),
                        ),
                      ),
                      // subtitle: Text(
                      //   store['address'] ?? 'Address',
                      //   style: TextStyle(color: Colors.grey[700]),
                      // ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF6A0DAD),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
