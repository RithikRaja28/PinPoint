// lib/screens/shops_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'shop_detail_screen.dart';
import '../globals.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopsListScreen extends StatefulWidget {
  final double? lat;
  final double? lon;

  const ShopsListScreen({Key? key, this.lat, this.lon}) : super(key: key);

  @override
  State<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends State<ShopsListScreen> {
  bool _loading = false;
  String? _error;
  List<Shop> _shops = [];
  String _query = "";

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  // ------------------ Replace _fetchShops and helpers with this ------------------
  Future<void> _fetchShops() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userLat = widget.lat ?? currentLat;
      final userLon = widget.lon ?? currentLong;

      // Hardcoded endpoint for local testing (you already had this)
      final uri = Uri.parse(
        "http://192.168.1.9:5000/shops/nearby?lat=13.082700&lon=80.270700&radius=10000000000",
      );

      final resp = await http.get(uri);

      // Debug: print raw body so you can inspect in console/logcat
      print("SHOPS RAW RESPONSE: ${resp.body}");

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);

        // Support both 'shops' (your backend) and 'nearby' (old format)
        final List<dynamic> list =
            (data['shops'] ?? data['nearby'] ?? []) as List<dynamic>;

        final shops = list.map((r) {
          // Helper to safely parse doubles from int/double/string
          double parseDouble(dynamic v) {
            if (v == null) return 0.0;
            if (v is double) return v;
            if (v is int) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? 0.0;
            return 0.0;
          }

          // distance can be named differently depending on backend
          final double dist = parseDouble(
            r['distanceMeters'] ??
                r['distance_m'] ??
                r['distance'] ??
                r['distance_meters'],
          );

          // Prefer lat/lon fields if present, otherwise try location_wkt
          final double lat = r.containsKey('lat')
              ? parseDouble(r['lat'])
              : _extractLat(r['location_wkt']);
          final double lon = r.containsKey('lon')
              ? parseDouble(r['lon'])
              : _extractLon(r['location_wkt']);

          // Choose image URL fallback if backend returns null/empty
          final String? imageUrlRaw = r['imageUrl'] as String?;
          final String imageUrl =
              (imageUrlRaw != null && imageUrlRaw.isNotEmpty)
              ? imageUrlRaw
              : "https://images.unsplash.com/photo-1556742400-b5d8d80d48f7?auto=format&fit=crop&w=1080&q=80";

          return Shop(
            id: (r['id'] is int)
                ? r['id'] as int
                : int.tryParse("${r['id']}") ?? 0,
            name: r['name'] ?? 'Unnamed',
            category: r['category'] ?? "General",
            lat: lat,
            lon: lon,
            avgSpend: parseDouble(r['avgSpend'] ?? r['avg_spend'] ?? 0),
            hasOffer: r['hasOffer'] ?? r['has_offer'] ?? false,
            distanceMeters: dist,
            snippet: r['snippet'] ?? r['address'] ?? "Local shop nearby",
            imageUrl: imageUrl,
            rating: parseDouble(r['rating'] ?? r['avg_rating'] ?? 4.0),
          );
        }).toList();

        // optional: sort by distance if you want nearest first
        shops.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

        if (mounted) setState(() => _shops = shops);
      } else {
        setState(() {
          _error = "Server returned ${resp.statusCode}";
          _shops = mockShops;
        });
      }
    } catch (e, st) {
      print("ERROR fetching shops: $e\n$st");
      setState(() {
        _error = "Error: $e";
        _shops = mockShops; // fallback to mocks
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _extractLat(String? wkt) {
    // Example WKT: "POINT(80.28358 13.06104)" -> returns second value (lat)
    if (wkt == null) return 0.0;
    try {
      final cleaned = wkt
          .replaceAll(RegExp(r'POINT\s*\('), '')
          .replaceAll(')', '')
          .trim();
      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        // WKT typically has lon first, lat second
        return double.tryParse(parts[1]) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  double _extractLon(String? wkt) {
    if (wkt == null) return 0.0;
    try {
      final cleaned = wkt
          .replaceAll(RegExp(r'POINT\s*\('), '')
          .replaceAll(')', '')
          .trim();
      final parts = cleaned.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        return double.tryParse(parts[0]) ?? 0.0;
      }
    } catch (_) {}
    return 0.0;
  }

  void _onSearchChanged(String q) {
    setState(() => _query = q);
    // small debounce could be added; for hackathon we call directly
    _fetchShops();
  }

  void _unfocus() => FocusScope.of(context).unfocus();
  Widget _imageFallback(Shop s) {
    return Container(
      color: const Color(0xFFF2F2F6),
      child: Center(
        child: Text(
          s.name.isNotEmpty ? s.name[0] : '',
          style: const TextStyle(fontSize: 24, color: Colors.black26),
        ),
      ),
    );
  }

  Widget _shopTile(Shop s) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            _unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: s)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Thumbnail (smaller to reduce pressure)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: s.imageUrl != null && s.imageUrl!.isNotEmpty
                          ? Image.network(
                              s.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, prog) {
                                if (prog == null) return child;
                                return Container(
                                  color: const Color(0xFFF2F2F6),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (ctx, e, st) => _imageFallback(s),
                            )
                          : _imageFallback(s),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row: title + offer badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (s.hasOffer)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFB39DDB),
                                    Color(0xFF7E57C2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'OFFER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Category (smaller)
                      Text(
                        s.category ?? "—",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),

                      const SizedBox(height: 8),

                      // Chips row that wraps if needed — avoids overflow
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _chipRowItem(
                            Icons.monetization_on,
                            "Avg ₹${s.avgSpend.toStringAsFixed(0)}",
                          ),
                          _chipRowItem(
                            Icons.location_on,
                            _formatDistance(s.distanceMeters),
                          ),
                          _ratingChip(s.rating), // compact rating
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Snippet (two lines)
                      Text(
                        s.snippet ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Chevron (compact)
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipRowItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _ratingChip(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return "${meters.round()} m";
    final km = (meters / 1000);
    return "${km.toStringAsFixed(1)} km";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocus,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF7F8FB),
        appBar: AppBar(
          title: const Text("Nearby Shops"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(onPressed: _fetchShops, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "Search shops, coffee, dessert...",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  maxLines: 1,
                ),
              ),

              if (_loading) const LinearProgressIndicator(),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchShops,
                  child: Builder(
                    builder: (ctx) {
                      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
                      return ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: bottomInset + 20,
                          top: 6,
                        ),
                        itemCount: _shops.length,
                        itemBuilder: (_, i) => _shopTile(_shops[i]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- Models & Mock Data -----------------
class Shop {
  final int id;
  final String name;
  final String? category;
  final double lat;
  final double lon;
  final double avgSpend;
  final bool hasOffer;
  final double distanceMeters;
  final String? snippet;
  final String? imageUrl;
  final double rating;

  Shop({
    required this.id,
    required this.name,
    this.category,
    required this.lat,
    required this.lon,
    required this.avgSpend,
    required this.hasOffer,
    required this.distanceMeters,
    this.snippet,
    this.imageUrl,
    this.rating = 4.2,
  });
}

final List<Shop> mockShops = [
  Shop(
    id: 1,
    name: "Bean & Brew",
    category: "Cafe",
    lat: 28.6315,
    lon: 77.2177,
    avgSpend: 150,
    hasOffer: true,
    distanceMeters: 320,
    snippet: "20% off on all lattes until 8PM",
    imageUrl:
        "https://images.unsplash.com/photo-1498804103079-a6351b050096?w=1200&q=80",
    rating: 4.6,
  ),
  Shop(
    id: 2,
    name: "Sweet Corner — Waffles & More (Very Long Name Example)",
    category: "Dessert",
    lat: 28.6322,
    lon: 77.2120,
    avgSpend: 80,
    hasOffer: false,
    distanceMeters: 540,
    snippet:
        "Best waffles nearby; try the special batter with honey and nuts (seasonal).",
    imageUrl:
        "https://images.unsplash.com/photo-1543933453-1b2bf4f01b36?w=1200&q=80",
    rating: 4.3,
  ),
  Shop(
    id: 3,
    name: "Rolls & More",
    category: "Street Food",
    lat: 28.6290,
    lon: 77.2150,
    avgSpend: 90,
    hasOffer: true,
    distanceMeters: 1200,
    snippet: "Buy 1 Get 1 (evenings)",
    imageUrl:
        "https://images.unsplash.com/photo-1544025162-d76694265947?w=1200&q=80",
    rating: 4.0,
  ),
  Shop(
    id: 4,
    name: "Cupcake House",
    category: "Bakery",
    lat: 28.6338,
    lon: 77.2198,
    avgSpend: 120,
    hasOffer: false,
    distanceMeters: 900,
    snippet: "Assorted cupcakes",
    imageUrl:
        "https://images.unsplash.com/photo-1604908177522-6a6d40d5d7a3?w=1200&q=80",
    rating: 4.5,
  ),
];
