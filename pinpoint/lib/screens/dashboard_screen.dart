import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final campaign =
        args ??
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Campaigns"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/create_campaign'),
            tooltip: 'Create campaign',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.04,
              vertical: screenSize.height * 0.02,
            ),
            child: Column(
              children: [
                // Header / Hero
                Hero(
                  tag: 'campaign-header',
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenSize.width * 0.04),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEDF2FF), Color(0xFFF7F3FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: screenSize.width * 0.15,
                          height: screenSize.width * 0.15,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.campaign_outlined,
                            color: Color(0xFF6A00F8),
                            size: 34,
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Recent Campaign',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                              SizedBox(height: screenSize.height * 0.005),
                              Text(
                                campaign['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.002),
                              Text(
                                '${campaign['offer']} • ${campaign['radius_km'].toStringAsFixed(1)} km',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Chip(
                              label: const Text('Active'),
                              backgroundColor: Colors.green[50],
                              labelStyle: const TextStyle(color: Colors.green),
                            ),
                            SizedBox(height: screenSize.height * 0.005),
                            Text(
                              '${DateFormat.yMMMd().format(start)} → ${DateFormat.yMMMd().format(end)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.025),
                // Quick stats row
                Row(
                  children: [
                    _StatCard(title: 'Impressions', value: '1.2k'),
                    SizedBox(width: screenSize.width * 0.03),
                    _StatCard(title: 'Clicks', value: '312'),
                    SizedBox(width: screenSize.width * 0.03),
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.03,
                            vertical: screenSize.height * 0.015,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Budget'),
                              SizedBox(height: screenSize.height * 0.008),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '\₹ 3,200',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Spent • 48%',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenSize.height * 0.008),
                              LinearProgressIndicator(
                                value: 0.48,
                                backgroundColor: Colors.grey[200],
                                color: const Color(0xFF7C4DFF),
                                minHeight: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenSize.height * 0.025),
                // Campaign Detail & Analytics
                Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenSize.width * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overview',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: screenSize.height * 0.015),
                            Text(campaign['offer']),
                            SizedBox(height: screenSize.height * 0.015),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18),
                                SizedBox(width: screenSize.width * 0.015),
                                Text(
                                  '${campaign['radius_km'].toStringAsFixed(1)} km radius',
                                ),
                                SizedBox(width: screenSize.width * 0.04),
                                const Icon(Icons.schedule, size: 18),
                                SizedBox(width: screenSize.width * 0.015),
                                Expanded(
                                  child: Text(
                                    '${DateFormat.yMMMd().add_jm().format(start)} → ${DateFormat.yMMMd().add_jm().format(end)}',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                  onPressed: () {},
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.share_outlined),
                                  label: const Text('Share'),
                                  onPressed: () {},
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('See analytics'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.015),
                    // Analytics Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenSize.width * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Engagement',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: screenSize.height * 0.015),
                            SizedBox(
                              height: screenSize.height * 0.15,
                              child: Center(
                                child: Text(
                                  'Mini chart placeholder',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: screenSize.height * 0.015,
            horizontal: screenSize.width * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: screenSize.height * 0.008),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
