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

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtr.text = widget.product!.name;
      _descCtr.text = widget.product!.description ?? "";
      _priceCtr.text = widget.product!.price.toString();
    }
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
          ? Uri.parse(
              "http://192.168.1.9:5000/api/products/${widget.product!.id}",
            )
          : Uri.parse("http://192.168.1.9:5000/api/products/");

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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Product" : "Create Product")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  color: Colors.grey.shade100,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (widget.product?.imageUrl != null
                            ? Image.network(
                                "http://192.168.1.9:5000${widget.product!.imageUrl!}",
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(Icons.add_a_photo, size: 48),
                              )),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtr,
                decoration: const InputDecoration(labelText: "Product name"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Enter a name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtr,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtr,
                decoration: const InputDecoration(labelText: "Price (₹)"),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Enter price";
                  final n = double.tryParse(v);
                  if (n == null) return "Invalid number";
                  if (n < 0) return "Price must be >= 0";
                  return null;
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Save" : "Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
