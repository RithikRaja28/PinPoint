import 'package:flutter/material.dart';
import 'package:pinpoint/screens/community_feed_screen.dart';
import 'package:pinpoint/screens/create_campaign_screen.dart';
import 'package:pinpoint/screens/dashboard_screen.dart';
import 'package:pinpoint/screens/customer_screen.dart'; // Import CustomerPage

class DashboardNavBar extends StatefulWidget {
  const DashboardNavBar({super.key});

  @override
  State<DashboardNavBar> createState() => _DashboardNavBarState();
}

class _DashboardNavBarState extends State<DashboardNavBar> {
  int _selectedIndex = 0;

  final _pages = const [
    DashboardScreen(),
    CreateCampaignScreen(),
    CommunityFeedScreen(),
    CustomerPage(), // Add CustomerPage here
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
}
