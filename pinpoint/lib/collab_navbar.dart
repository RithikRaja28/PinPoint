// // collab_navbar.dart
// import 'package:flutter/material.dart';
// import 'package:pinpoint/screens/collab_request_list.dart';
// import 'package:pinpoint/screens/community_feed_screen.dart';
// import 'package:pinpoint/screens/customer_screen.dart';

// class CollabNavBar extends StatefulWidget {
//   const CollabNavBar({super.key});

//   @override
//   State<CollabNavBar> createState() => _CollabNavBarState();
// }

// class _CollabNavBarState extends State<CollabNavBar> {
//   int _selectedIndex = 0;

//   final _pages = [
//     ColobRequestList(),
//     const CustomerPage(),
//     const CommunityFeedScreen(),
//     CustomerPage(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: (i) => setState(() => _selectedIndex = i),
//         backgroundColor: const Color(0xFF6A00F8),
//         indicatorColor: Colors.white24,
//         labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(
//               Icons.store_mall_directory_outlined,
//               color: Colors.white,
//             ),
//             selectedIcon: Icon(Icons.store, color: Colors.white),
//             label: "Stores",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.shopping_cart_outlined, color: Colors.white),
//             selectedIcon: Icon(Icons.shopping_cart, color: Colors.white),
//             label: "Orders",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.people_outline, color: Colors.white),
//             selectedIcon: Icon(Icons.people, color: Colors.white),
//             label: "Community",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.person_outline, color: Colors.white),
//             selectedIcon: Icon(Icons.person, color: Colors.white),
//             label: "Customer",
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinpoint/screens/collab_request_list.dart';
import 'package:pinpoint/screens/community_feed_screen.dart';
import 'package:pinpoint/screens/customer_screen.dart';
import 'package:pinpoint/globals.dart';
import 'package:pinpoint/user_model.dart';

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
    const CustomerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final UserModel? user = currentUser;

    return Scaffold(
      // Top AppBar
      appBar: AppBar(
        title: Text(_getPageTitle(_selectedIndex)),
        backgroundColor: const Color(0xFF6A00F8),
        automaticallyImplyLeading: false,
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(user.name, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              currentUser = null;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),

      // Body
      body: _pages[_selectedIndex],

      // Bottom Navigation Bar
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

  // Helper: get AppBar title based on selected tab
  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return "Stores";
      case 1:
        return "Orders";
      case 2:
        return "Community";
      case 3:
        return "Customer Dashboard";
      default:
        return "";
    }
  }
}
