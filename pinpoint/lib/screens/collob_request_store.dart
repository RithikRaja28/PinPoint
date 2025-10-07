import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollobRequestStore extends StatelessWidget {
  final String storeId;

  const CollobRequestStore({Key? key, required this.storeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6A0DAD),
      appBar: AppBar(
        title: Text("Store Details"),
        backgroundColor: Color(0xFF6A0DAD),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          var store = snapshot.data!;
          return Padding(
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store['name'] ?? 'Store Name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A0DAD),
                      ),
                    ),
                    SizedBox(height: 10),
                    // Text(
                    //   store['address'] ?? 'Address',
                    //   style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    // ),
                    SizedBox(height: 20),
                    // Text(
                    //   store['description'] ?? 'No description available.',
                    //   style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    // ),
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
