// import 'package:flutter/material.dart';
// import 'package:pinpoint/screens/community_feed_screen.dart';
// import 'package:pinpoint/screens/create_campaign_screen.dart';
// import 'package:pinpoint/screens/dashboard_screen.dart';
// import 'package:pinpoint/screens/customer_screen.dart'; // Import CustomerPage

// class DashboardNavBar extends StatefulWidget {
//   const DashboardNavBar({super.key});

//   @override
//   State<DashboardNavBar> createState() => _DashboardNavBarState();
// }

// class _DashboardNavBarState extends State<DashboardNavBar> {
//   int _selectedIndex = 0;

//   final _pages = const [
//     DashboardScreen(),
//     CreateCampaignScreen(),
//     CommunityFeedScreen(),
//     CustomerPage(), // Add CustomerPage here
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
//             icon: Icon(Icons.dashboard_outlined, color: Colors.white),
//             selectedIcon: Icon(Icons.dashboard, color: Colors.white),
//             label: "Dashboard",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.campaign_outlined, color: Colors.white),
//             selectedIcon: Icon(Icons.campaign, color: Colors.white),
//             label: "Campaigns",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.people_alt_outlined, color: Colors.white),
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
import 'package:pinpoint/screens/create_campaign_screen.dart';
import 'package:pinpoint/screens/dashboard_screen.dart';
import 'package:pinpoint/screens/customer_screen.dart';
import 'package:pinpoint/globals.dart';
import 'package:pinpoint/user_model.dart';

class DashboardNavBar extends StatefulWidget {
  const DashboardNavBar({super.key});

  @override
  State<DashboardNavBar> createState() => _DashboardNavBarState();
}

class _DashboardNavBarState extends State<DashboardNavBar> {
  int _selectedIndex = 0;

  final _pages = [
    const DashboardScreen(),
    const CreateCampaignScreen(),
    const CommunityFeedScreen(),
    ColobRequestList(),
  ];

  @override
  Widget build(BuildContext context) {
    final UserModel? user = currentUser;

    return Scaffold(
      // Top AppBar with user icon and sign-out
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
            icon: Icon(Icons.dashboard_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.dashboard, color: Colors.white),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.campaign, color: Colors.white),
            label: "Campaigns",
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined, color: Colors.white),
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

  // Helper function to get page title based on index
  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return "Dashboard";
      case 1:
        return "Campaigns";
      case 2:
        return "Community";
      case 3:
        return "Customer Dashboard";
      default:
        return "";
    }
  }
}
