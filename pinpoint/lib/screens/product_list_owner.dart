import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../config.dart'; // API_BASE

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
        _error = "Not signed in";
        _loading = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(
        "http://192.168.1.9:5000/api/products?owner_uid=${Uri.encodeComponent(user.uid)}",
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final Map data = json.decode(resp.body);
        final List list = data['products'] ?? [];
        setState(() {
          _products = list
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        setState(() {
          _error = "Server error: ${resp.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goCreate() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductEditScreen()),
    );
    if (res == true) _fetchMyProducts();
  }

  void _goEdit(Product p) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductEditScreen(product: p)),
    );
    if (res == true) _fetchMyProducts();
  }

  Future<void> _deleteProduct(Product p) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete product"),
        content: Text("Delete ${p.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final uri = Uri.parse(
        "http://192.168.1.9:5000/api/products/${p.id}?owner_uid=${Uri.encodeComponent(user.uid)}",
      );
      final resp = await http.delete(uri);
      if (resp.statusCode == 200) {
        _fetchMyProducts();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Deleted")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Products"),
        actions: [
          IconButton(
            onPressed: _fetchMyProducts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(onPressed: _goCreate, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _fetchMyProducts,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _products.length,
                itemBuilder: (_, i) {
                  final p = _products[i];
                  return Card(
                    child: ListTile(
                      leading: p.imageUrl != null
                          ? Image.network(
                              "http://192.168.1.9:5000${p.imageUrl!}",
                              width: 56,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(width: 56, child: Icon(Icons.image)),
                      title: Text(p.name),
                      subtitle: Text("₹${p.price.toStringAsFixed(2)}"),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _goEdit(p);
                          if (v == 'delete') _deleteProduct(p);
                        },
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
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
