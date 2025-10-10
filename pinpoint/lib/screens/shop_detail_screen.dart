// lib/screens/shop_detail_screen.dart
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shops_list_screen.dart';
import 'package:http/http.dart' as http;
import 'package:pinpoint/config.dart'; // ensure apiUrl is exported here

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
  List<Map<String, dynamic>> _campaigns = []; // store all campaigns

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ownerUid = widget.shop.ownerUid;
      if (ownerUid == null || ownerUid.isEmpty) {
        setState(() {
          _error = "Missing owner ID for this shop.";
          _products = mockProductsByShop[widget.shop.id] ?? [];
          _campaigns = [];
        });
        return;
      }

      final uri = Uri.parse(
        '$apiUrl/shops/shopdetails_and_campaigns?owner_uid=$ownerUid',
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Server returned ${resp.statusCode}';
          _products = mockProductsByShop[widget.shop.id] ?? [];
          _campaigns = [];
        });
        return;
      }

      final Map<String, dynamic> data = json.decode(resp.body);
      debugPrint('shop details response: ${resp.body}');

      // parse products list
      final List productsData = (data['products'] ?? []) as List;
      final parsedProducts = productsData.map((p) {
        final id = p['id'] is int ? p['id'] : int.tryParse('${p['id']}') ?? 0;
        final price = (p['price'] != null)
            ? (p['price'] is num
                  ? (p['price'] as num).toDouble()
                  : double.tryParse('${p['price']}') ?? 0.0)
            : 0.0;
        return Product(
          id: id,
          name: p['name'] ?? 'Unnamed',
          description: p['description'],
          price: price,
          savings: p.containsKey('savings') && p['savings'] != null
              ? (p['savings'] is num
                    ? (p['savings'] as num).toDouble()
                    : double.tryParse('${p['savings']}'))
              : null,
          imageUrl: p['image_url'] ?? p['imageUrl'] ?? p['image'],
        );
      }).toList();

      // parse campaigns - accept any list of maps
      final List campaignsData = (data['campaigns'] ?? []) as List;
      final parsedCampaigns = campaignsData.map<Map<String, dynamic>>((c) {
        if (c is Map<String, dynamic>) return c;
        // defensive: if objects are not map-typed, attempt decode
        return Map<String, dynamic>.from(c as Map);
      }).toList();

      setState(() {
        _products = parsedProducts.isNotEmpty
            ? parsedProducts
            : (mockProductsByShop[widget.shop.id] ?? []);
        _campaigns = parsedCampaigns;
      });
    } catch (e, st) {
      debugPrint('Error fetching shop details: $e\n$st');
      setState(() {
        _error = "Error: $e";
        _products = mockProductsByShop[widget.shop.id] ?? [];
        _campaigns = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Campaign card now accepts a `cardHeight` and scales internal image/text accordingly.
  Widget _campaignCard(
    Map<String, dynamic> c, {
    required double cardHeight,
    double? width,
  }) {
    if (c.isEmpty) return const SizedBox.shrink();
    final title = c['title'] ?? 'Offer';
    final offer = c['offer'] ?? '';
    final poster =
        c['poster_path'] ?? c['posterPath'] ?? c['poster'] ?? c['poster_url'];
    final start = c['start']?.toString();
    final end = c['end']?.toString();

    String posterUrl = '';
    if (poster != null && poster.toString().isNotEmpty) {
      final posterStr = poster.toString();
      posterUrl = posterStr.startsWith('/') ? (apiUrl + posterStr) : posterStr;
    }

    // width adaptive (keeps previous behaviour)
    final cardWidth =
        width ?? (MediaQuery.of(context).size.width * 0.86).clamp(240.0, 520.0);

    // derive image size from cardHeight so total content fits
    final double sidePadding = 10.0 * 2; // padding inside Material
    final double actionsWidth = 76; // approximate width for the action column
    final double availableHeight = cardHeight - 20; // some breathing room
    final double imageSize = (availableHeight * 0.62).clamp(56.0, 84.0);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        elevation: 1.8,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            height: cardHeight - 10, // make internal size match cardHeight
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // poster / image with dynamic size
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: posterUrl.isNotEmpty
                        ? Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF2F2F6),
                              child: const Icon(Icons.local_offer_outlined),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF2F2F6),
                            child: const Icon(Icons.local_offer_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title row
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        offer,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (start != null)
                            Flexible(
                              child: Text(
                                "Starts: ${_shortDate(start)}",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (end != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Ends: ${_shortDate(end)}",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // actions - keep narrow so card doesn't expand vertically
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Campaign action (demo)"),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text("View"),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Share campaign (demo)"),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      child: const Text("Share"),
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

  Widget _sectionHeader(String title, {int? count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB39DDB), Color(0xFF7E57C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  title.toLowerCase().contains('offer')
                      ? Icons.local_offer
                      : Icons.shopping_bag,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: _fetchDetails,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  static String _shortDate(String input) {
    try {
      final d = DateTime.parse(input);
      return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return input;
    }
  }

  Widget _emptyState({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB39DDB), Color(0xFF7E57C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 56,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
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
                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                    ? Image.network(
                        p.imageUrl!.startsWith('/')
                            ? apiUrl + p.imageUrl!
                            : p.imageUrl!,
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
                      )
                    : Container(
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

            const SizedBox(width: 12),

            // content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.description!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

    // Compute a dynamic campaign area height based on screen height.
    // Keeps it between 110 and 150 and uses a proportion on very tall devices.
    final double campaignHeight = (() {
      final double byScreen = mq.size.height * 0.16;
      return byScreen.clamp(110.0, 150.0);
    })();

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // banner (sliver adapter)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: bannerHeight),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          (s.imageUrl != null &&
                                  s.imageUrl!.isNotEmpty &&
                                  s.imageUrl!.startsWith('/')
                              ? apiUrl + s.imageUrl!
                              : (s.imageUrl ?? '')),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${s.category ?? '—'} • Avg ₹${s.avgSpend.toStringAsFixed(0)} • ${_formatDistance(s.distanceMeters)}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
            ),

            // Directions button
            SliverToBoxAdapter(
              child: Padding(
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
            ),

            // small spacing / loading
            SliverToBoxAdapter(child: const SizedBox(height: 10)),

            if (_loading)
              SliverToBoxAdapter(
                child: const LinearProgressIndicator(color: kPrimary),
              ),

            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

            // Offers header
            SliverToBoxAdapter(
              child: _sectionHeader(
                "Offers",
                count: _campaigns.isNotEmpty ? _campaigns.length : 0,
              ),
            ),

            // Offers horizontal list — now uses dynamic campaignHeight and passes cardHeight to each card
            if (_campaigns.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: campaignHeight, // dynamic height
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    scrollDirection: Axis.horizontal,
                    itemCount: _campaigns.length,
                    itemBuilder: (ctx, i) => _campaignCard(
                      _campaigns[i],
                      cardHeight: campaignHeight - 8, // pass inner height
                    ),
                  ),
                ),
              ),

            if (_campaigns.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "No active offers right now. Check back later for promotions.",
                          ),
                        ),
                        TextButton(
                          onPressed: _fetchDetails,
                          child: const Text("Refresh"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // small spacing
            SliverToBoxAdapter(child: const SizedBox(height: 8)),

            // Products header and list
            if (_products.isEmpty)
              SliverFillRemaining(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _emptyState(
                    title: "No products available",
                    body:
                        "This shop doesn't have any listed products yet. You can still view the store or contact them.",
                  ),
                ),
              )
            else
              // list of products as sliver list
              SliverList(
                delegate: SliverChildBuilderDelegate((ctx, index) {
                  if (index == 0) {
                    return _sectionHeader("Products", count: _products.length);
                  }
                  final product = _products[index - 1];
                  return _productCard(product);
                }, childCount: _products.length + 1),
              ),

            // bottom padding so last item isn't glued to nav bars
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
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

// keep your existing mocks as a fallback
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
