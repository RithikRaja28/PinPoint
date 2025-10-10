// lib/screens/business/business_profile.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinpoint/globals.dart';

class BusinessProfile extends StatefulWidget {
  const BusinessProfile({super.key});

  @override
  State<BusinessProfile> createState() => _BusinessProfileState();
}

class _BusinessProfileState extends State<BusinessProfile> {
  String _selectedCategory = "Restaurant";

  final List<Map<String, dynamic>> _categories = [
    {"name": "Restaurant", "icon": Icons.restaurant_menu},
    {"name": "Retail", "icon": Icons.store_mall_directory},
    {"name": "Salon", "icon": Icons.content_cut},
    {"name": "Electronics", "icon": Icons.devices_other},
    {"name": "Other", "icon": Icons.category},
  ];

  Future<String> translateString(String text) async {
    try {
      final translated = await globalTranslator.translate(
        text,
        to: selectedLang,
      );
      return translated.text;
    } catch (_) {
      return text;
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.deepPurple.shade700, size: 22),
        ),
        title: translateText(label),
        subtitle: Text(
          value.isNotEmpty ? value : 'Not provided',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;
    if (user == null) {
      return Center(child: translateText("No business data found"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: translateText("Business Profile"),
        iconTheme: const IconThemeData(color: Color(0xFF4A148C)),
        actions: [
          DropdownButton<String>(
            value: selectedLang,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Color(0xFF4A148C)),
            dropdownColor: Colors.white,
            items: ['en', 'es', 'fr', 'de', 'hi', 'ta'].map((lang) {
              return DropdownMenuItem<String>(
                value: lang,
                child: Text(
                  lang.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => selectedLang = value);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🌈 Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7E57C2), Color(0xFF9575CD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(45),
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.shopName?.isNotEmpty == true
                                ? user.shopName![0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A148C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user.shopName ?? "Business Owner",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    translateText("Welcome back 👋"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 📋 Business Information Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const Icon(Icons.store, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    translateText("Business Information"),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _buildInfoTile(Icons.phone, "Contact", user.shopContact ?? ''),
              if (user.address != null)
                _buildInfoTile(Icons.location_on, "Address", user.address!),
              if (user.city != null)
                _buildInfoTile(Icons.location_city, "City", user.city!),
              if (user.description != null)
                _buildInfoTile(Icons.info_outline, "About", user.description!),

              const SizedBox(height: 32),

              // 🏷️ Category Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const Icon(Icons.category, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    translateText("Business Category"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: FutureBuilder<String>(
                  future: translateString("Select Category"),
                  builder: (context, snapshot) {
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: snapshot.data ?? "Select Category",
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _selectedCategory,
                      items: _categories
                          .map<DropdownMenuItem<String>>(
                            (cat) => DropdownMenuItem<String>(
                              value: cat["name"],
                              child: Row(
                                children: [
                                  Icon(
                                    cat["icon"],
                                    color: Colors.deepPurple.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  translateText(cat["name"]),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategory = val!);
                      },
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.deepPurple.shade600,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // 🛍️ Manage Products Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.inventory_2_outlined, size: 22),
                    label: const Text(
                      "Manage Products",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/owner_products');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E57C2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // 🚪 Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      currentUser = null;
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      backgroundColor: const Color(0xFFB39DDB),
                      foregroundColor: Colors.white,
                    ),
                    label: translateText("Sign Out"),
                  ),
                ),
              ),

              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
}
