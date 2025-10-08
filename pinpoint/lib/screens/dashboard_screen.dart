import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinpoint/globals.dart'; // 🟢 Import for translateText and selectedLang

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<String> languages = ['en', 'es', 'fr', 'de', 'hi', 'ta'];

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
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: translateText("📊 Campaign Dashboard"), // 🟢 Translated title
        actions: [
          DropdownButton<String>(
            value: selectedLang,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.deepPurple),
            dropdownColor: Colors.white,
            items: languages.map((lang) {
              return DropdownMenuItem<String>(
                value: lang,
                child: Text(
                  lang.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedLang = value);
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F7FF), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.05,
              vertical: screenSize.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerCard(screenSize, campaign, start, end),
                const SizedBox(height: 25),
                _horizontalScrollStats(screenSize),
                const SizedBox(height: 25),
                _overviewCard(screenSize, campaign, start, end),
                const SizedBox(height: 25),
                _analyticsCard(screenSize),
                const SizedBox(height: 25),
                _communityCard(context, screenSize),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HEADER CARD
  Widget _headerCard(
      Size screenSize, Map<String, dynamic> campaign, DateTime start, DateTime end) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: EdgeInsets.all(screenSize.width * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenSize.width * 0.18,
            height: screenSize.width * 0.18,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 42),
          ),
          SizedBox(width: screenSize.width * 0.05),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                translateText("Recent Campaign"),
                const SizedBox(height: 6),
                Text(
                  campaign['title'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                Text('${campaign['offer']} • ${campaign['radius_km']} km',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _softActiveBadge("ACTIVE"),
        ],
      ),
    );
  }

  // ACTIVE BADGE
  Widget _softActiveBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10, color: Colors.white),
          const SizedBox(width: 6),
          translateText(text),
        ],
      ),
    );
  }

  // STATS CARDS
  Widget _horizontalScrollStats(Size screenSize) {
    final stats = [
      {'title': 'Impressions', 'value': '1.2k', 'icon': Icons.remove_red_eye},
      {'title': 'Clicks', 'value': '312', 'icon': Icons.touch_app},
      {'title': 'Conversions', 'value': '68', 'icon': Icons.trending_up},
      {'title': 'Budget Used', 'value': '48%', 'icon': Icons.account_balance},
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

  // OVERVIEW CARD
  Widget _overviewCard(Size screenSize, Map<String, dynamic> campaign,
      DateTime start, DateTime end) {
    return _HoverCardContainer(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            translateText('📌 Overview'),
            const SizedBox(height: 10),
            Text(campaign['offer'],
                style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.deepPurple, size: 18),
                const SizedBox(width: 6),
                translateText('${campaign['radius_km']} km radius'),
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
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _glossyButton(
                    text: "Edit",
                    icon: Icons.edit,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A00F8), Color(0xFF9575CD)],
                    ),
                    onTap: () {}),
                _glossyButton(
                    text: "Share",
                    icon: Icons.share_outlined,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFAB47BC), Color(0xFFE1BEE7)],
                    ),
                    onTap: () {}),
                _glassButton("Analytics", onTap: () {}),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ANALYTICS CARD
  Widget _analyticsCard(Size screenSize) {
    return _HoverCardContainer(
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            translateText('📈 Engagement Insights'),
            const SizedBox(height: 15),
            Container(
              height: screenSize.height * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                ),
              ),
              child: Center(child: translateText('Coming Soon 🚀')),
            ),
          ],
        ),
      ),
    );
  }

  // COMMUNITY CARD
  Widget _communityCard(BuildContext context, Size screenSize) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/community'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A00F8), Color(0xFF9C4DFF)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: EdgeInsets.all(screenSize.width * 0.06),
        child: Row(
          children: [
            const Icon(Icons.people_alt_rounded,
                color: Colors.white, size: 44),
            SizedBox(width: screenSize.width * 0.05),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  translateText('Community Connect'),
                  const SizedBox(height: 6),
                  translateText(
                      'Join local campaigns, share insights, and grow together!'),
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

  // BUTTONS
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
              color: Colors.deepPurple.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            translateText(text),
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
        child: translateText(text),
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
                  ? Colors.deepPurple.withOpacity(0.2)
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
                color: const Color(0xFF6A00F8), size: _hover ? 30 : 26),
            const SizedBox(height: 8),
            Text(widget.value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2C1A63))),
            translateText(widget.title),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _hover
                  ? Colors.deepPurple.withOpacity(0.15)
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
