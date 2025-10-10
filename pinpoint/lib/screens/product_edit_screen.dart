// lib/screens/business/product_edit_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../config.dart';

class ProductEditScreen extends StatefulWidget {
  final Product? product;
  const ProductEditScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _descCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  File? _imageFile;
  bool _saving = false;
  final ImagePicker _picker = ImagePicker();

  // brand
  static const Color brandDark = Color(0xFF6A00F8);
  static const Color brandMid = Color(0xFF7C4DFF);
  static const Color neutralBg = Color(0xFFF5F3FE);

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtr.text = widget.product!.name;
      _descCtr.text = widget.product!.description ?? "";
      _priceCtr.text = widget.product!.price.toString();
    }
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _descCtr.dispose();
    _priceCtr.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pick = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (pick != null) setState(() => _imageFile = File(pick.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Not signed in")));
      return;
    }
    setState(() => _saving = true);

    try {
      final bool isUpdate =
          widget.product != null && widget.product!.id != null;
      final uri = isUpdate
          ? Uri.parse('$apiUrl/api/products/${widget.product!.id}')
          : Uri.parse('$apiUrl/api/products/');

      final req = http.MultipartRequest(isUpdate ? 'PUT' : 'POST', uri);
      req.fields['owner_uid'] = user.uid;
      req.fields['name'] = _nameCtr.text.trim();
      req.fields['description'] = _descCtr.text.trim();
      req.fields['price'] = _priceCtr.text.trim();

      if (_imageFile != null) {
        req.files.add(
          await http.MultipartFile.fromPath('image', _imageFile!.path),
        );
      }

      final streamed = await req.send();
      final respStr = await streamed.stream.bytesToString();
      if (streamed.statusCode == 201 || streamed.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        String msg = "Failed (${streamed.statusCode})";
        try {
          final j = json.decode(respStr);
          if (j['error'] != null) msg += ": ${j['error']}";
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildImageArea() {
    final borderRadius = BorderRadius.circular(14.0);

    Widget child;
    if (_imageFile != null) {
      child = ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    } else if (widget.product?.imageUrl != null) {
      child = ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          '$apiUrl${widget.product!.imageUrl!}',
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _placeholderBox(borderRadius),
        ),
      );
    } else {
      child = _placeholderBox(borderRadius);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: brandMid.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            // overlay gradient + camera icon
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [brandMid, brandDark]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox(BorderRadius borderRadius) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.add_a_photo, size: 48, color: Colors.black26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      backgroundColor: neutralBg,
      appBar: AppBar(
        title: Text(
          isEdit ? "Edit Product" : "Create Product",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: brandMid,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // header card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [brandMid.withOpacity(0.14), Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title & subtitle
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [brandMid, brandDark],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: brandMid.withOpacity(0.12),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fastfood,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit
                                      ? "Update product details"
                                      : "Add a new product",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Provide a clear name, price and a short description.",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildImageArea(),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // fields card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: brandMid.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtr,
                        decoration: InputDecoration(
                          labelText: "Product name",
                          labelStyle: TextStyle(color: Colors.grey.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: brandMid),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Enter a name"
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtr,
                        decoration: InputDecoration(
                          labelText: "Description",
                          labelStyle: TextStyle(color: Colors.grey.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: brandMid),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtr,
                        decoration: InputDecoration(
                          labelText: "Price (₹)",
                          labelStyle: TextStyle(color: Colors.grey.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: brandMid),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return "Enter price";
                          final n = double.tryParse(v);
                          if (n == null) return "Invalid number";
                          if (n < 0) return "Price must be >= 0";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // actions row: cancel + save
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: brandMid,
                          foregroundColor: Colors.white,
                          elevation: 6,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEdit ? "Save changes" : "Create product",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
