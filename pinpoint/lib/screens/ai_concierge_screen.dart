import 'dart:math';
import 'package:flutter/material.dart';

class AIConciergeScreen extends StatefulWidget {
  const AIConciergeScreen({super.key});

  @override
  State<AIConciergeScreen> createState() => _AIConciergeScreenState();
}

class _AIConciergeScreenState extends State<AIConciergeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<dynamic> _results = [];

  // 🔹 Predefined static recommendation sets
  final List<List<Map<String, dynamic>>> _mockRecommendations = [
    [
      {"name": "Bean & Brew Café", "category": "Cafe", "avg_spend": 180},
      {"name": "Java Junction", "category": "Coffee Shop", "avg_spend": 210},
      {"name": "Brew Street", "category": "Cafe", "avg_spend": 240},
    ],
    [
      {"name": "Urban Threads", "category": "Clothing", "avg_spend": 350},
      {"name": "StyleNest", "category": "Fashion", "avg_spend": 280},
      {"name": "Trend Avenue", "category": "Boutique", "avg_spend": 320},
    ],
    [
      {"name": "FitNation Gym", "category": "Fitness", "avg_spend": 250},
      {"name": "Pulse Studio", "category": "Workout", "avg_spend": 270},
      {"name": "Muscle Factory", "category": "Gym", "avg_spend": 300},
    ],
    [
      {"name": "SugarRush", "category": "Dessert", "avg_spend": 150},
      {"name": "Bake Bliss", "category": "Bakery", "avg_spend": 180},
      {"name": "SweetTooth Corner", "category": "Dessert", "avg_spend": 120},
    ],
    [
      {"name": "The Spice Hub", "category": "Restaurant", "avg_spend": 400},
      {"name": "Masala Avenue", "category": "Dining", "avg_spend": 350},
      {"name": "Tandoori Tales", "category": "Restaurant", "avg_spend": 300},
    ],
    [
      {"name": "Street Flavors", "category": "Street Food", "avg_spend": 100},
      {"name": "Chaat Point", "category": "Street Food", "avg_spend": 80},
      {"name": "Roll Express", "category": "Quick Bites", "avg_spend": 90},
    ],
    [
      {"name": "Tech Haven", "category": "Electronics", "avg_spend": 500},
      {"name": "Gadget Zone", "category": "Electronics", "avg_spend": 450},
      {"name": "Mobile World", "category": "Retail", "avg_spend": 480},
    ],
    [
      {"name": "Blossom Beauty", "category": "Salon", "avg_spend": 300},
      {"name": "Glow Studio", "category": "Salon", "avg_spend": 350},
      {"name": "Elegance Lounge", "category": "Spa", "avg_spend": 320},
    ],
    [
      {"name": "BookNest", "category": "Bookstore", "avg_spend": 200},
      {"name": "Readers Den", "category": "Books", "avg_spend": 180},
      {"name": "Novel Point", "category": "Books", "avg_spend": 220},
    ],
    [
      {"name": "MovieTown", "category": "Entertainment", "avg_spend": 250},
      {"name": "FunZone Arcade", "category": "Games", "avg_spend": 200},
      {"name": "CineSquare", "category": "Cinema", "avg_spend": 280},
    ],
  ];

  // 🔹 Simulate AI recommendation locally
  Future<void> _fetchRecommendations() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    await Future.delayed(const Duration(seconds: 2)); // Simulate API delay

    try {
      final randomSet = _mockRecommendations[Random().nextInt(_mockRecommendations.length)];
      setState(() => _results = randomSet);
    } catch (e) {
      setState(() => _error = "Something went wrong!");
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔹 Recommendation Card
  Widget _buildRecommendationCard(dynamic item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        title: Text(
          item["name"] ?? "Unknown Shop",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF4A148C),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "${item["category"] ?? "N/A"} • ₹${item["avg_spend"] ?? "—"}",
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF6A00F8)),
      ),
    );
  }

  Widget _loadingIndicator() => const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(
            color: Color(0xFF7C4DFF),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: const Text(
          "AI Local Concierge",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A00F8), Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Search bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFF6A00F8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: "e.g. I have ₹200 for coffee ☕",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _fetchRecommendations(),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _fetchRecommendations,
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF6A00F8)),
                  ),
                ],
              ),
            ),

            if (_loading) _loadingIndicator(),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // 🔹 Results Section
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          "Ask me where to spend your time & money! 💡",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) =>
                            _buildRecommendationCard(_results[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
