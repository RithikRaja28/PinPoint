import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final campaign = args ??
        {
          'title': 'Demo Campaign',
          'offer': '20% off coffee',
          'radius_km': 1.0,
          'start': DateTime.now().toIso8601String(),
          'end': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'hasPoster': false,
        };

    final start = DateTime.parse(campaign['start']);
    final end = DateTime.parse(campaign['end']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Campaign Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.6,
            color: Color(0xFF2C1A63),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF6A00F8), size: 28),
            tooltip: 'Create campaign',
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/create_campaign'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.04,
            vertical: screenSize.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(screenSize, campaign, start, end, context),
              const SizedBox(height: 25),
              _horizontalScrollStats(screenSize),
              const SizedBox(height: 25),
              _overviewCard(screenSize, context, campaign, start, end),
              const SizedBox(height: 25),
              _analyticsCard(screenSize),
              const SizedBox(height: 25),
              _communityCard(context, screenSize),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Header with Neon Active Badge ======
  Widget _headerCard(Size screenSize, Map<String, dynamic> campaign,
      DateTime start, DateTime end, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF9C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenSize.width * 0.17,
            height: screenSize.width * 0.17,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: Colors.white, size: 40),
          ),
          SizedBox(width: screenSize.width * 0.05),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Recent Campaign",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(campaign['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('${campaign['offer']} • ${campaign['radius_km']} km',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          _neonBadge("ACTIVE"),
        ],
      ),
    );
  }

  // Neon Active Badge
  Widget _neonBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF69F0AE)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ====== Scrollable Stats ======
  Widget _horizontalScrollStats(Size screenSize) {
    final stats = [
      {'title': 'Impressions', 'value': '1.2k', 'icon': Icons.remove_red_eye},
      {'title': 'Clicks', 'value': '312', 'icon': Icons.touch_app},
      {'title': 'Conversions', 'value': '68', 'icon': Icons.trending_up},
      {'title': 'Budget Spent', 'value': '48%', 'icon': Icons.account_balance},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats
            .map(
              (s) => _HoverCard(
                width: screenSize.width * 0.45,
                title: s['title'].toString(),
                value: s['value'].toString(),
                icon: s['icon'] as IconData,
              ),
            )
            .toList(),
      ),
    );
  }

  // ====== Overview Card with Stylish Buttons ======
  Widget _overviewCard(Size screenSize, BuildContext context,
      Map<String, dynamic> campaign, DateTime start, DateTime end) {
    return _HoverCardContainer(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF2C1A63))),
            const SizedBox(height: 10),
            Text(campaign['offer'], style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.purple, size: 18),
                const SizedBox(width: 6),
                Text('${campaign['radius_km']} km radius'),
                const SizedBox(width: 16),
                const Icon(Icons.schedule, color: Colors.indigo, size: 18),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        '${DateFormat.yMMMd().add_jm().format(start)} → ${DateFormat.yMMMd().add_jm().format(end)}',
                        style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _glossyButton(
                  text: "Edit",
                  icon: Icons.edit,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A00F8), Color(0xFF7E57C2)],
                  ),
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _glossyButton(
                  text: "Share",
                  icon: Icons.share_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C4DFF), Color(0xFFCE93D8)],
                  ),
                  onTap: () {},
                ),
                const SizedBox(width: 10),
                _glassButton("Analytics", onTap: () {}),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ====== Analytics Card ======
  Widget _analyticsCard(Size screenSize) {
    return _HoverCardContainer(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Engagement',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF2C1A63))),
            const SizedBox(height: 15),
            Container(
              height: screenSize.height * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                ),
              ),
              child: const Center(
                child: Text(
                  '📊 Engagement Insights Coming Soon',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== Community Section ======
  Widget _communityCard(BuildContext context, Size screenSize) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/community'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A00F8), Color(0xFF9C4DFF)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: EdgeInsets.all(screenSize.width * 0.06),
        child: Row(
          children: [
            const Icon(Icons.people_alt_rounded, color: Colors.white, size: 44),
            SizedBox(width: screenSize.width * 0.05),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Community Connect',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text(
                    'Join local campaigns, share insights, and connect!',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ====== Glossy Gradient Buttons ======
  Widget _glossyButton({
    required String text,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassButton(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          border: Border.all(color: const Color(0xFF6A00F8), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF6A00F8), fontSize: 14),
        ),
      ),
    );
  }
}

// ======= Hover Card for Stats =======
class _HoverCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final double width;
  const _HoverCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.width});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 12),
        width: widget.width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _hover
                  ? Colors.deepPurple.withOpacity(0.25)
                  : Colors.black12.withOpacity(0.05),
              blurRadius: _hover ? 14 : 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon,
                color: const Color(0xFF6A00F8),
                size: _hover ? 30 : 26),
            const SizedBox(height: 8),
            Text(widget.value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2C1A63))),
            Text(widget.title,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ======= Hover Container =======
class _HoverCardContainer extends StatefulWidget {
  final Widget child;
  const _HoverCardContainer({required this.child});

  @override
  State<_HoverCardContainer> createState() => _HoverCardContainerState();
}

class _HoverCardContainerState extends State<_HoverCardContainer> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _hover
                  ? Colors.deepPurple.withOpacity(0.2)
                  : Colors.black12.withOpacity(0.05),
              blurRadius: _hover ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
