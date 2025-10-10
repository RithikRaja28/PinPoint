import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  static const String apiBase = "http://192.168.1.9:5000/api"; // ✅ Update IP

  Future<void> _fetchRecommendations() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final uri = Uri.parse("$apiBase/recommend");
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _results = data["results"] ?? [];
        });
      } else {
        setState(() {
          _error = "Server error: ${resp.statusCode}";
        });
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

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
          )
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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

  Widget _loadingShimmer() => const Center(
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 145, 65, 164)),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 133, 86, 138)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
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
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: Color(0xFF6A00F8)),
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
                    icon: const Icon(Icons.send_rounded,
                        color: Color(0xFF6A00F8)),
                  ),
                ],
              ),
            ),

            if (_loading) _loadingShimmer(),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          "Ask me where to spend your time & money!",
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
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
