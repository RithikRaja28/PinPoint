import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinpoint/collab_navbar.dart';
import 'package:pinpoint/dashboard_navbar.dart';
import 'package:pinpoint/globals.dart';
import 'package:pinpoint/screens/auth_screen.dart';
import 'package:pinpoint/user_model.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _loading = true;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // ✅ Step 1: Check Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    // If not signed in at all
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // ✅ Step 2: If global currentUser already loaded, skip Firestore read
    if (currentUser != null) {
      _userType = currentUser!.userType == UserType.business
          ? 'business'
          : 'normal';
      setState(() => _loading = false);
      return;
    }

    // ✅ Step 3: Try loading from Firestore only once if needed
    try {
      // Check both collections based on login pattern
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        _userType = currentUser!.userType == UserType.business
            ? 'business'
            : 'normal';
      } else {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(user.uid)
            .get();
        if (storeDoc.exists) {
          currentUser = UserModel.fromMap(
            storeDoc.data() as Map<String, dynamic>,
          );
          _userType = currentUser!.userType == UserType.business
              ? 'business'
              : 'normal';
        }
      }
    } catch (e) {
      print("Error initializing user: $e");
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ While checking
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ Not logged in OR global currentUser not set
    if (FirebaseAuth.instance.currentUser == null || currentUser == null) {
      return const AuthScreen();
    }

    // ✅ Redirect based on user type
    return _userType == 'business'
        ? const DashboardNavBar()
        : const CollabNavBar();
  }
}
