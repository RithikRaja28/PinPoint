// collab_navbar.dart
import 'package:flutter/material.dart';
import 'package:pinpoint/screens/collab_request_list.dart';
import 'package:pinpoint/screens/community_feed_screen.dart';
import 'package:pinpoint/screens/customer_screen.dart';

class CollabNavBar extends StatefulWidget {
  const CollabNavBar({super.key});

  @override
  State<CollabNavBar> createState() => _CollabNavBarState();
}

class _CollabNavBarState extends State<CollabNavBar> {
  int _selectedIndex = 0;

  final _pages = [
    ColobRequestList(),
    const CustomerPage(),
    const CommunityFeedScreen(),
    CustomerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF6A00F8),
        indicatorColor: Colors.white24,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.store_mall_directory_outlined,
              color: Colors.white,
            ),
            selectedIcon: Icon(Icons.store, color: Colors.white),
            label: "Stores",
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.shopping_cart, color: Colors.white),
            label: "Orders",
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: Colors.white),
            selectedIcon: Icon(Icons.people, color: Colors.white),
            label: "Community",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: "Customer",
          ),
        ],
      ),
    );
  }
}
