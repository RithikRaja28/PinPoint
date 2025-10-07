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

  final _pages = const [
    DashboardScreen(),
    CreateCampaignScreen(),
    CommunityFeedScreen(),
    ColobRequestList(),
  ];

  @override
  Widget build(BuildContext context) {
    final UserModel? user = currentUser;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey[100],

      // ---------- TOP APP BAR ----------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A00F8), Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ---- App Logo + Name ----
                  Row(
                    children: const [
                      Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 6),
                      Text(
                        "PinPoint",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // ---- Avatar + Logout ----
                  Row(
                    children: [
                      if (user != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CustomerPage()),
                            );
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: "Logout",
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          currentUser = null;
                          if (context.mounted) {
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil('/', (r) => false);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ---------- BODY ----------
      body: _pages[_selectedIndex],

      // ---------- BOTTOM NAVBAR ----------
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: Colors.transparent,
            backgroundColor: Colors.white,
            labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
              (states) {
                if (states.contains(MaterialState.selected)) {
                  return const TextStyle(
                    color: Color(0xFF6A00F8), // Violet for selected
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                }
                return const TextStyle(
                  color: Colors.grey, // Grey for unselected
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                );
              },
            ),
          ),
          child: NavigationBar(
            height: 65,
            backgroundColor: Colors.white,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, "Dashboard", 0),
              _buildNavItem(Icons.campaign_outlined, Icons.campaign, "Campaigns", 1),
              _buildNavItem(Icons.people_alt_outlined, Icons.people, "Community", 2),
              _buildNavItem(Icons.person_outline, Icons.person, "Requests", 3),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- NAV ITEM BUILDER ----------
  NavigationDestination _buildNavItem(
      IconData icon, IconData selectedIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return NavigationDestination(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected
              ? const Color(0xFF6A00F8) // Violet when active
              : Colors.grey, // Grey when inactive
          size: isSelected ? 28 : 26,
          shadows: isSelected
              ? [
                  const Shadow(
                    color: Color(0x336A00F8),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
      ),
      label: label,
    );
  }
}
