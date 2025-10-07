// lib/screens/shop_detail_screen.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shops_list_screen.dart';

const Color kPrimary = Color(0xFF7E57C2);
const Color kAccentLight = Color(0xFFEDE7F6);

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  const ShopDetailScreen({Key? key, required this.shop}) : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  bool _loading = false;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // mocked
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _products = mockProductsByShop[widget.shop.id] ?? [];
      });
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _productCard(Product p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.network(
                  p.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, st) => Container(
                    color: const Color(0xFFF2F2F6),
                    child: Center(
                      child: Text(
                        p.name.isNotEmpty ? p.name[0] : '',
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (p.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.description!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _priceTag(p.price),
                      if (p.savings != null) ...[
                        const SizedBox(width: 8),
                        _saveTag(p.savings!),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Share this item",
                  icon: const Icon(Icons.share),
                  color: kPrimary,
                  onPressed: () => _showShareSheet(p),
                ),
                const SizedBox(height: 4),
                IconButton(
                  tooltip: "Promote / Comment",
                  icon: const Icon(Icons.campaign),
                  color: kPrimary,
                  onPressed: () => _showPromoteDialog(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceTag(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: kAccentLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "₹${price.toStringAsFixed(0)}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _saveTag(double saving) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Save ₹${saving.toStringAsFixed(0)}",
        style: const TextStyle(color: Colors.green),
      ),
    );
  }

  Future<void> _openDirections(double lat, double lon) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
    );
    final mapsGeoUrl = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(mapsGeoUrl)) {
        await launchUrl(mapsGeoUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (!kIsWeb) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      } else {
        await launchUrl(googleMapsUrl);
        return;
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open maps on this device.")),
      );
    }
  }

  void _showShareSheet(Product p) {
    final s = widget.shop;
    final shareText =
        "${p.name} at ${s.name} — ₹${p.price.toStringAsFixed(0)}. Find it on PinPoint!";
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Share \"${p.name}\"",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(shareText),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // TODO: wire share_plus
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Share action (demo)")),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPromoteDialog(Product p) async {
    final TextEditingController ctl = TextEditingController();
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Promote / Comment on \"${p.name}\""),
          content: TextField(
            controller: ctl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  "Write a quick note (e.g., 'Great taste — try with extra chilli')",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Post"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (res == true && ctl.text.trim().isNotEmpty) {
      // TODO: send to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thanks — your comment was posted (demo)"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shop;
    final mq = MediaQuery.of(context);
    final bannerHeight = min(220.0, mq.size.height * 0.28);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          s.name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: bannerHeight),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // image
                      Image.network(
                        s.imageUrl ?? '',
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF2F2F6),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, st) =>
                            Container(color: const Color(0xFFF2F2F6)),
                      ),
                      // purple gradient overlay (modern touch)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimary.withOpacity(0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${s.category ?? '—'} • Avg ₹${s.avgSpend.toStringAsFixed(0)} • ${_formatDistance(s.distanceMeters)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${s.rating.toStringAsFixed(1)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "rating",
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions - Directions (page-level)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openDirections(s.lat, s.lon),
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text(
                        "Directions",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            if (_loading) const LinearProgressIndicator(color: kPrimary),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            // products
            Expanded(
              child: _products.isEmpty && !_loading
                  ? const Center(child: Text("No products or offers found"))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => _productCard(_products[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return "${meters.round()} m";
    final km = (meters / 1000);
    return "${km.toStringAsFixed(1)} km";
  }
}

// ----------------- Product model & mocks -----------------
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? savings;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.savings,
    this.imageUrl,
  });
}

final Map<int, List<Product>> mockProductsByShop = {
  1: [
    Product(
      id: 101,
      name: "Cappuccino",
      description: "Rich espresso + steamed milk",
      price: 130,
      savings: 26,
      imageUrl:
          "https://images.unsplash.com/photo-1511920170033-f8396924c348?w=800&q=60",
    ),
    Product(
      id: 102,
      name: "Veg Sandwich",
      description: "Fresh veggies & chutney",
      price: 110,
      imageUrl:
          "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=60",
    ),
  ],
  2: [
    Product(
      id: 201,
      name: "Belgian Waffle",
      description: "Served warm with syrup",
      price: 90,
      imageUrl:
          "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&q=60",
    ),
    Product(
      id: 202,
      name: "Chocolate Shake",
      description: "Creamy and thick",
      price: 70,
      imageUrl:
          "https://images.unsplash.com/photo-1582719478250-9e5f4e1d1a8c?w=800&q=60",
    ),
  ],
  3: [
    Product(
      id: 301,
      name: "Paneer Roll",
      description: "Spicy paneer wrap",
      price: 60,
      savings: 30,
      imageUrl:
          "https://images.unsplash.com/photo-1546069901-eacef0df6022?w=800&q=60",
    ),
    Product(
      id: 302,
      name: "Masala Fries",
      description: "Crispy spiced fries",
      price: 50,
      imageUrl:
          "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=60",
    ),
  ],
  4: [
    Product(
      id: 401,
      name: "Red Velvet Cupcake",
      description: null,
      price: 140,
      imageUrl:
          "https://images.unsplash.com/photo-1606755962777-1f5f7d7d2a42?w=800&q=60",
    ),
    Product(
      id: 402,
      name: "Blueberry Muffin",
      description: null,
      price: 80,
      imageUrl:
          "https://images.unsplash.com/photo-1559628233-1fcf8b9ae7b0?w=800&q=60",
    ),
  ],
};
