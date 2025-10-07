import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinpoint/user_model.dart'; // your UserModel
import 'package:pinpoint/globals.dart'; // if you store currentUser globally

class CustomerPage extends StatelessWidget {
  const CustomerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user from globals (or pass it via constructor)
    final UserModel? current_User = currentUser;

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Customer Dashboard"),
      //   automaticallyImplyLeading: false,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: () async {
      //         // Sign out from Firebase
      //         await FirebaseAuth.instance.signOut();

      //         // Clear currentUser globally
      //         currentUser = null;

      //         // Navigate back to root
      //         Navigator.of(
      //           context,
      //         ).pushNamedAndRemoveUntil('/', (route) => false);
      //       },
      //     ),
      //   ],
      // ),
      body: Center(
        child: currentUser == null
            ? const Text("No user found")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Welcome, ${currentUser?.name}!",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Email: ${currentUser?.email}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Phone: ${currentUser?.phone}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      currentUser = null;
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Sign Out"),
                  ),
                ],
              ),
      ),
    );
  }
}
