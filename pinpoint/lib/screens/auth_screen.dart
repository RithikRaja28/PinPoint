// auth_screen.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pinpoint/services/map_picker_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinpoint/globals.dart';
import 'package:pinpoint/user_model.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pinpoint/config.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // state
  UserType _selectedUserType = UserType.business;
  AuthMode _authMode = AuthMode.login;

  final _formKey = GlobalKey<FormState>();

  // grouped categories
  final Map<String, List<String>> _categoryGroups = {
    'Food & Beverage': [
      'Restaurant',
      'Cafe',
      'Bakery',
      'Juice Center',
      'Street Food',
    ],
    'Retail': ['Clothing', 'Electronics', 'Grocery', 'Jewellery', 'Bookstore'],
    'Services': ['Salon / Spa', 'Laundry', 'Repair & Maintenance', 'Tailor'],
    'Health & Wellness': ['Pharmacy', 'Clinic', 'Fitness Center'],
    'Entertainment': ['Movie Theatre', 'Gaming Zone', 'Event Space'],
    'Others': ['Other'],
  };

  // selected group & subcategory
  String? _selectedCategoryGroup;
  String? _selectedSubcategory;

  // registration number
  final _registrationController = TextEditingController();

  // avg spend
  final _avgSpendController = TextEditingController();

  // image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _shopImageFile;
  File? _logoFile; // kept but you mentioned logo not required; harmless to keep

  // backend API base (update to your backend)
  static const String BACKEND_BASE = 'https://your-backend.example.com';

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopContactController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _descriptionController = TextEditingController();
  LatLng? _shopLocation;

  final bool _otpSent = false;
  bool _loading = false;
  final String _generatedOtp = "";

  // animations
  late final AnimationController _gradientController;
  late final AnimationController _tabsController;

  Future<void> _showConsentDialogs() async {
    final steps = [
      {
        "title": "Welcome to PinPoint",
        "message":
            "We respect your privacy. We’ll only use your phone number and location to verify offers and improve your experience.",
        "positive": "I Agree and Continue",
        "negative": "View Privacy Policy",
        "icon": Icons.privacy_tip,
      },
      {
        "title": "Number Verification",
        "message":
            "PinPoint needs to verify your mobile number to create your account securely. This verification happens automatically using your mobile network.",
        "positive": "Allow Number Verification",
        "negative": "Cancel",
        "icon": Icons.phone_iphone,
      },
      {
        "title": "Fraud Check",
        "message":
            "To protect your rewards, PinPoint may verify if your SIM card was recently changed. This helps prevent fraud.",
        "positive": "Allow Fraud Check",
        "negative": "No, skip this offer",
        "icon": Icons.security,
      },
      {
        "title": "Location Access",
        "message":
            "PinPoint needs access to your device’s location to show nearby offers and verify you are at a store when redeeming.",
        "positive": "Allow Location Access",
        "negative": "Don't Allow",
        "icon": Icons.location_on,
      },
    ];

    Future<bool?> showStepDialog({
      required Map<String, dynamic> step,
      required int stepIndex,
    }) {
      final size = MediaQuery.of(context).size;
      return showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: "Consent",
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (ctx, anim1, anim2, child) {
          return Transform.translate(
            offset: Offset(0, (1 - anim1.value) * 50),
            child: Opacity(
              opacity: anim1.value,
              child: Center(
                child: Container(
                  width: size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Step indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            steps.length,
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == stepIndex ? 16 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i <= stepIndex
                                    ? const Color(0xFF6A00F8)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Icon
                        Icon(
                          step['icon'],
                          color: const Color(0xFF6A00F8),
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          step['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Message
                        Text(
                          step['message'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Responsive Buttons
                        Row(
                          children: [
                            Flexible(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    step['negative'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A00F8),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    step['positive'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    for (int i = 0; i < steps.length; i++) {
      await showStepDialog(step: steps[i], stepIndex: i);
    }

    Navigator.pushReplacementNamed(context, '/');
  }

  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login
          ? AuthMode.signup
          : AuthMode.login;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _tabsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // no user logged in → stay on login page

    // Fetch user details from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final userData = doc.data();
    if (userData == null) return;

    // Determine navigation route
    final userType = userData['userType'];
    // if (userType == 'business') {
    //   Navigator.pushReplacementNamed(context, '/dashboard');
    // } else {
    //   Navigator.pushReplacementNamed(context, '/colab_request');
    // }

    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _tabsController.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _shopNameController.dispose();
    _shopContactController.dispose();
    _registrationController.dispose();
    _avgSpendController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        if (isLogo) {
          _logoFile = File(picked.path);
        } else {
          _shopImageFile = File(picked.path);
        }
      });
      _showSnack("${isLogo ? 'Logo' : 'Image'} selected");
    } catch (e) {
      _showSnack("Failed to pick image: $e");
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickShopLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() => _shopLocation = result);
      _showSnack("Location selected!");
    }
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserType == UserType.business && _shopLocation == null) {
      _showSnack("Select shop location");
      return;
    }

    try {
      _showSnack("Creating account...");

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      final userModel = UserModel(
        uid: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        userType: _selectedUserType,
        shopName: _selectedUserType == UserType.business
            ? _shopNameController.text.trim()
            : null,
        shopContact: _selectedUserType == UserType.business
            ? _shopContactController.text.trim()
            : null,
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        shopLat: _selectedUserType == UserType.business
            ? _shopLocation?.latitude ?? 20.5937
            : null,
        shopLng: _selectedUserType == UserType.business
            ? _shopLocation?.longitude ?? 78.9629
            : null,
      );
      currentUser = userModel;
      print(_selectedUserType);
      print("\n");
      final collectionName = _selectedUserType == UserType.business
          ? 'stores'
          : 'users';

      print("${collectionName} jjjjjjj");

      // 1) Write base user/store document to Firestore (existing behaviour)
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .set(userModel.toMap());
      await updateFcmToken(FCM_TOKEN, userModel.phone);

      // 2) Create/merge extended shop fields into Firestore (so Firestore contains complete shop info)
      final chosenCategory = _selectedSubcategory ?? _selectedCategoryGroup;
      double? avgSpendDouble;
      if (_avgSpendController.text.trim().isNotEmpty) {
        avgSpendDouble = double.tryParse(_avgSpendController.text.trim());
      }

      final Map<String, dynamic> shopExtra = {};

      if (_selectedUserType == UserType.business) {
        if (chosenCategory != null && chosenCategory.trim().isNotEmpty) {
          shopExtra['category'] = chosenCategory;
        }
        if (_registrationController.text.trim().isNotEmpty) {
          shopExtra['registration_no'] = _registrationController.text
              .trim()
              .toUpperCase();
        }
        if (_shopContactController.text.trim().isNotEmpty) {
          shopExtra['shopContact'] = _shopContactController.text.trim();
        }
        if (avgSpendDouble != null) shopExtra['avg_spend'] = avgSpendDouble;
        if (_descriptionController.text.trim().isNotEmpty)
          shopExtra['description'] = _descriptionController.text.trim();
        if (_addressController.text.trim().isNotEmpty)
          shopExtra['address'] = _addressController.text.trim();

        // store location as map for Firestore usage
        if (_shopLocation != null) {
          shopExtra['shopLocation'] = {
            'lat': _shopLocation!.latitude,
            'lng': _shopLocation!.longitude,
          };
        }
      }

      if (shopExtra.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(uid)
            .set(shopExtra, SetOptions(merge: true));
      }

      // 3) collabs / cities (existing behaviour)
      await FirebaseFirestore.instance.collection("collabs").doc(uid).set({
        'shops': [],
      });

      await FirebaseFirestore.instance
          .collection("cities")
          .doc(_cityController.text.trim())
          .set({
            'shops': FieldValue.arrayUnion([uid]),
          }, SetOptions(merge: true));

      // --- create shop record in your Postgres backend ---
      try {
        // Build multipart request
        final uri = Uri.parse('$apiUrl/shops/');
        final req = http.MultipartRequest('POST', uri);

        // required/primary fields
        req.fields['name'] = _shopNameController.text.trim();
        req.fields['address_line'] = _addressController.text.trim();
        req.fields['city'] = _cityController.text.trim();

        // category: prefer subcategory, fallback to group
        if (chosenCategory != null && chosenCategory.trim().isNotEmpty) {
          req.fields['category'] = chosenCategory;
        }

        if (_registrationController.text.trim().isNotEmpty) {
          req.fields['registration_no'] = _registrationController.text
              .trim()
              .toUpperCase();
        }
        if (_shopContactController.text.trim().isNotEmpty) {
          req.fields['contact_number'] = _shopContactController.text.trim();
        }
        if (avgSpendDouble != null) {
          req.fields['avg_spend'] = avgSpendDouble.toString();
        }

        // owner link — helpful to connect postgres <-> firebase
        req.fields['owner_uid'] = uid;

        if (_descriptionController.text.trim().isNotEmpty) {
          req.fields['description'] = _descriptionController.text.trim();
        }

        // location (lat/lon)
        if (_shopLocation != null) {
          req.fields['lat'] = _shopLocation!.latitude.toString();
          req.fields['lon'] = _shopLocation!.longitude.toString();
        }

        // optionally attach images (shop image). logo is optional & kept for backward compatibility.
        if (_shopImageFile != null) {
          final img = await http.MultipartFile.fromPath(
            'image',
            _shopImageFile!.path,
          );
          req.files.add(img);
        }
        if (_logoFile != null) {
          final logo = await http.MultipartFile.fromPath(
            'logo',
            _logoFile!.path,
          );
          req.files.add(logo);
        }

        final streamed = await req.send();
        final resp = await http.Response.fromStream(streamed);

        if (resp.statusCode == 201 || resp.statusCode == 200) {
          // success: backend returns created shop JSON (best-effort parse)
          _showSnack('Shop registered on backend');
          print('Shop backend resp: ${resp.body}');

          // try to merge returned useful fields into Firestore (id, image_url, logo_url)
          try {
            final Map<String, dynamic> parsed =
                jsonDecode(resp.body) as Map<String, dynamic>;

            // common patterns: {"id":..., "image_url": "..."} or {"shop": {...}}
            final Map<String, dynamic> backendShop = parsed.containsKey('shop')
                ? (parsed['shop'] as Map<String, dynamic>)
                : parsed;

            final Map<String, dynamic> backendUpdates = <String, dynamic>{};

            if (backendShop.containsKey('id')) {
              backendUpdates['backend_id'] = backendShop['id'];
            }
            if (backendShop.containsKey('image_url')) {
              backendUpdates['image_url'] = backendShop['image_url'];
            } else if (backendShop.containsKey('image')) {
              backendUpdates['image_url'] = backendShop['image'];
            }
            if (backendShop.containsKey('logo_url')) {
              backendUpdates['logo_url'] = backendShop['logo_url'];
            } else if (backendShop.containsKey('logo')) {
              backendUpdates['logo_url'] = backendShop['logo'];
            }

            if (backendUpdates.isNotEmpty) {
              await FirebaseFirestore.instance
                  .collection(collectionName)
                  .doc(uid)
                  .set(backendUpdates, SetOptions(merge: true));
            }
          } catch (e) {
            // if parsing fails, ignore — not critical
            print('Could not parse backend response JSON: $e');
          }
        } else {
          // non-fatal: backend failed; keep going but notify
          _showSnack('Shop backend returned ${resp.statusCode}');
          print('Backend error: ${resp.statusCode} ${resp.body}');
        }
      } catch (e) {
        // do not block signup on backend failure
        print('Failed to create shop in backend: $e');
        _showSnack('Could not register shop to server (demo)');
      }

      _showSnack("Signup successful for ${_selectedUserType.name}");
      await Future.delayed(const Duration(milliseconds: 500));
      if (_selectedUserType == UserType.business) {
        _showConsentDialogs();
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      String message = "Signup failed. Please try again.";
      if (e.code == 'email-already-in-use') {
        message = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        message = "Your password is too weak.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format.";
      }
      _showSnack(message);
    } catch (e) {
      _showSnack("Something went wrong: $e");
    }
  }

  // helper widgets

  // animated gradient header
  Widget _buildHeroHeader(BuildContext ctx) {
    final size = MediaQuery.of(ctx).size;
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (_, __) {
        final t = _gradientController.value;
        final colorA = Color.lerp(
          const Color(0xFF7C4DFF),
          const Color(0xFFB39DDB),
          t,
        )!;
        final colorB = Color.lerp(
          const Color(0xFF6A00F8),
          const Color(0xFFD1C4E9),
          t,
        )!;
        return Container(
          width: double.infinity,
          height: size.height * 0.30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorA, colorB],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(48),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Floating abstract shapes
              Positioned(
                top: 20,
                left: -30,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                right: -40,
                child: Transform.rotate(
                  angle: 0.6,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + title
                    Row(
                      children: [
                        Hero(
                          tag: 'pin-logo',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFF6A00F8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.pin_drop,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "PinPoint",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Get discovered locally",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Tagline + subtle dots
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _authMode == AuthMode.login
                                ? "Welcome back!"
                                : "Create your account",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(3, (i) {
                            final alpha =
                                (1 -
                                        (_gradientController.value - i * 0.15)
                                            .abs())
                                    .clamp(0.2, 1.0);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(alpha * 0.9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Tab row with animated underline
  Widget _buildModeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(36),
              onTap: () {
                setState(() {
                  _authMode = AuthMode.login;
                });
                _tabsController.reverse();
              },
              child: SizedBox(
                height: 46,
                child: Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      color: _authMode == AuthMode.login
                          ? const Color(0xFF4A148C)
                          : Colors.grey[700],
                      fontWeight: _authMode == AuthMode.login
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(36),
              onTap: () {
                setState(() {
                  _authMode = AuthMode.signup;
                });
                _tabsController.forward();
              },
              child: SizedBox(
                height: 46,
                child: Center(
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      color: _authMode == AuthMode.signup
                          ? const Color(0xFF4A148C)
                          : Colors.grey[700],
                      fontWeight: _authMode == AuthMode.signup
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabUnderline() {
    return AnimatedBuilder(
      animation: _tabsController,
      builder: (_, __) {
        // _tabsController value 0 -> login, 1 -> signup
        final lerp = _tabsController.value;
        return Align(
          alignment: Alignment(-1 + (lerp * 2), 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: (MediaQuery.of(context).size.width - 64) / 2 - 8,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF6A00F8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withOpacity(0.18),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Glass input wrapper
  Widget _glassField({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return _glassField(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        validator: (val) => val!.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  // Fancy primary button
  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF6A00F8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _typeSelectRow() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          _typeChip("Business", UserType.business),
          const SizedBox(width: 8),
          _typeChip("Customer", UserType.normal),
        ],
      ),
    );
  }

  Widget _typeChip(String label, UserType type) {
    final selected = _selectedUserType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserType = type;
            print(_selectedUserType); // optional for debug
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDE7F6) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? const Color(0xFF7C4DFF) : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF4A148C) : Colors.grey[800],
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Form(
      key: loginFormKey, // use the global key here
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            "Welcome back",
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[900],
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sign in using your email and password",
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 18),

          _buildInput(
            controller: _emailController,
            label: "Email",
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          _buildInput(
            controller: _passwordController,
            label: "Password",
            obscure: true,
          ),
          const SizedBox(height: 16),

          _primaryButton(
            label: "Sign In",
            onPressed: _loading ? null : _signInWithEmailPassword,
          ),

          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _authMode = AuthMode.signup;
                  _tabsController.forward();
                });
              },
              child: const Text(
                "Create an account",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithEmailPassword() async {
    findLocation();
    if (!loginFormKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1️⃣ Sign in with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final uid = userCredential.user!.uid;

      // 2️⃣ Try to fetch user from "users" collection first
      final String collectionUsed = _selectedUserType == UserType.business
          ? 'stores'
          : 'users';

      // Fetch the document only from the relevant collection
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(collectionUsed)
          .doc(uid)
          .get();

      // 4️⃣ Initialize UserModel exactly like signup
      if (userDoc.exists) {
        final userData = userDoc.data()! as Map<String, dynamic>;

        currentUser = UserModel(
          uid: userData['uid'],
          name: userData['name'],
          email: userData['email'],
          phone: userData['phone'],
          userType: userData['userType'] == 'business'
              ? UserType.business
              : UserType.normal,
          shopName: userData['shopName'],
          shopContact: userData['shopContact'],
          shopLat: userData['shopLocation']?['lat']?.toDouble(),
          shopLng: userData['shopLocation']?['lng']?.toDouble(),
          createdAt: userData['createdAt'],
          city: userData['city'],
          district: userData['district'],
          description: userData['description'],
          address: userData['address'],
        );

        // ✅ Optional: Store globally for app session
        // Globals.currentUser = currentUser;

        _showSnack("Welcome back, ${currentUser?.name}!");
        print(
          "Logged in user type: ${currentUser?.userType}, collection: $collectionUsed",
        );

        // if (_selectedUserType == UserType.business) {
        //   Navigator.pushReplacementNamed(context, '/dashboard');
        // } else {
        //   Navigator.pushReplacementNamed(context, '/customer');
        // }
        Navigator.pushReplacementNamed(context, '/');
      } else {
        _showSnack("User not found, check the Usertype.");
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        message = "No account found with this email.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password.";
      }
      _showSnack(message);
    } catch (e) {
      _showSnack("Something went wrong: $e");
    } finally {
      setState(() => _loading = false);
    }
    // findLocation();
  }

  Widget _signupCard() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            "Create Account",
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[900],
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Join PinPoint and reach customers nearby",
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 18),
          _buildInput(controller: _nameController, label: "Full name"),
          const SizedBox(height: 12),
          _buildInput(controller: _emailController, label: "Email"),
          const SizedBox(height: 12),
          _buildInput(
            controller: _phoneController,
            label: "Mobile number",
            keyboard: TextInputType.phone,
          ),
          _buildInput(
            controller: _cityController,
            label: "City / Town (in lowercase without space)",
          ),
          const SizedBox(height: 12),
          _buildInput(
            controller: _districtController,
            label: "District (in lowercase without space)",
          ),
          const SizedBox(height: 12),
          _buildInput(
            controller: _passwordController,
            label: "Password",
            obscure: true,
          ),
          if (_selectedUserType == UserType.business) ...[
            const SizedBox(height: 12),
            _buildInput(controller: _shopNameController, label: "Shop name"),
            const SizedBox(height: 12),
            _buildInput(
              controller: _shopContactController,
              label: "Shop contact No",
            ),
            const SizedBox(height: 12),
            _buildInput(controller: _addressController, label: "Full Address"),
            const SizedBox(height: 12),
            _buildInput(
              controller: _descriptionController,
              label: "Description",
            ),
            const SizedBox(height: 12),

            // shop location picker (compact row)
            GestureDetector(
              onTap: _pickShopLocation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _shopLocation == null
                      ? Colors.white
                      : const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _shopLocation == null
                        ? Colors.grey.shade200
                        : const Color(0xFF7C4DFF),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _shopLocation == null
                          ? Colors.grey[600]
                          : const Color(0xFF6A00F8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _shopLocation == null
                            ? "Select shop location"
                            : "Location selected",
                        style: TextStyle(
                          color: _shopLocation == null
                              ? Colors.grey[700]
                              : const Color(0xFF4A148C),
                        ),
                      ),
                    ),
                    if (_shopLocation != null)
                      IconButton(
                        onPressed: () => setState(() => _shopLocation = null),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category group (primary) & subcategory
            Text("Category", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategoryGroup,
                  hint: const Text("Select category group"),
                  isExpanded: true,
                  items: _categoryGroups.keys
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCategoryGroup = v;
                      _selectedSubcategory = null;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_selectedCategoryGroup != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubcategory,
                    hint: const Text("Select subcategory (optional)"),
                    isExpanded: true,
                    items: (_categoryGroups[_selectedCategoryGroup] ?? [])
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSubcategory = v),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Registration number
            _buildInput(
              controller: _registrationController,
              label: "Registration No (GST/shop id)",
            ),

            const SizedBox(height: 12),

            // Avg spend
            _glassField(
              child: TextFormField(
                controller: _avgSpendController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Avg. spend (₹)",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final n = double.tryParse(val);
                  if (n == null || n < 0) return "Enter valid amount";
                  return null;
                },
              ),
            ),

            const SizedBox(height: 12),

            // Single Image picker (shop image)
            OutlinedButton.icon(
              onPressed: () => _pickImage(false),
              icon: const Icon(Icons.photo),
              label: Text(
                _shopImageFile == null ? "Upload shop image" : "Change image",
              ),
            ),

            if (_shopImageFile != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _shopImageFile!,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],

          const SizedBox(height: 18),
          _primaryButton(label: "Sign Up", onPressed: _submitSignup),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ensure tabs controller synced
    if (_authMode == AuthMode.login) {
      _tabsController.reverse();
    } else {
      _tabsController.forward();
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: const Color(0xFF6A00F8), // your blue/purple shade
        // statusBarIconBrightness: Brightness.light, // for light icons on dark bg
        // statusBarBrightness: Brightness.dark, // for iOS devices
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // hero header
            _buildHeroHeader(context),

            // main content area (overlapping card)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                child: Column(
                  children: [
                    // floating card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // user type selector
                            _typeSelectRow(),
                            const SizedBox(height: 14),

                            // tabs + underline
                            _buildModeTabs(),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 6,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  _buildTabUnderline(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // animated content
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 300),
                              firstChild: _loginCard(),
                              secondChild: _signupCard(),
                              crossFadeState: _authMode == AuthMode.login
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // soft footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "By continuing you agree to our ",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Terms",
                          style: TextStyle(
                            color: const Color(0xFF6A00F8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
