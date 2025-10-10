// lib/screens/business/product_list_owner.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../config.dart'; // apiUrl
import 'product_edit_screen.dart';

class ProductListOwner extends StatefulWidget {
  const ProductListOwner({Key? key}) : super(key: key);

  @override
  State<ProductListOwner> createState() => _ProductListOwnerState();
}

class _ProductListOwnerState extends State<ProductListOwner> {
  bool _loading = false;
  List<Product> _products = [];
  String? _error;

  // Brand colors (same as campaign screen)
  static const Color brandDark = Color(0xFF6A00F8);
  static const Color brandMid = Color(0xFF7C4DFF);
  static const Color brandLight = Color(0xFFEDE2FF);
  static const Color neutralBg = Color(0xFFF5F3FE);

  @override
  void initState() {
    super.initState();
    _fetchMyProducts();
  }

  Future<void> _fetchMyProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = "You are not signed in. Please sign in to manage products.";
        _loading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(
        '$apiUrl/api/products?owner_uid=${Uri.encodeComponent(user.uid)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(resp.body);
        final List list = data['products'] ?? [];
        setState(() {
          _products = list
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else if (resp.statusCode == 404) {
        setState(() => _products = []);
      } else {
        setState(() => _error = "Server error: ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goCreate() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProductEditScreen()),
    );
    if (res == true) _fetchMyProducts();
  }

  void _goEdit(Product p) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductEditScreen(product: p)),
    );
    if (res == true) _fetchMyProducts();
  }

  Future<void> _deleteProduct(Product p) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not signed in")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete ${p.name}?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final uri = Uri.parse(
        '$apiUrl/api/products/${p.id}?owner_uid=${Uri.encodeComponent(user.uid)}',
      );
      final resp = await http.delete(uri);
      if (resp.statusCode == 200) {
        await _fetchMyProducts();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Product deleted")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: ${resp.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: brandMid.withOpacity(0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No products yet",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add your first product so customers can discover them in your shop.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Add Product"),
              onPressed: _goCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandMid,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 72, color: Colors.grey),
            const SizedBox(height: 18),
            const Text(
              "Oops",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _fetchMyProducts,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _fetchMyProducts,
      color: brandMid,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _products.length,
        itemBuilder: (_, i) {
          final p = _products[i];
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(14),
              shadowColor: brandMid.withOpacity(0.12),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _goEdit(p),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // gradient accent strip
                    Container(
                      width: 6,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: p.imageUrl != null
                                  ? Image.network(
                                      '$apiUrl${p.imageUrl!}',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: brandMid,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "₹${p.price.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.description ?? '',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // three-dots menu (centered vertically)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _goEdit(p);
                                    if (v == 'delete') _deleteProduct(p);
                                  },
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.grey,
                                    size: 22,
                                  ),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                  // Remove internal padding for better alignment
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralBg,
      appBar: AppBar(
        title: const Text(
          "My Products",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: brandMid,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _fetchMyProducts,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            onPressed: _goCreate,
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goCreate,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Product",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: brandMid,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
          ? _buildErrorState(_error!)
          : (_products.isEmpty)
          ? _buildEmptyState()
          : _buildList(),
    );
  }
}
