import 'package:flutter/material.dart';
import 'package:pinpoint/screens/collob_request_store.dart';
import 'package:pinpoint/screens/colob_request_list.dart';
import 'package:pinpoint/screens/create_campaign_screen.dart';
import 'package:pinpoint/screens/customer_screen.dart';
import 'package:pinpoint/screens/dashboard_screen.dart';
import 'package:pinpoint/screens/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pinpoint/services/phone_auth_service.dart';
import 'package:pinpoint/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Then initialize Firebase
  await Firebase.initializeApp();

  runApp(const CampaignApp());
}

class CampaignApp extends StatelessWidget {
  const CampaignApp({super.key});

  // Pastel / light palette + accent gradient
  static const Color primary = Color(0xFF6A00F8);
  static const Color accent = Color(0xFF7C4DFF);
  static const Color bg = Color(0xFFF7F8FB);
  static const Color surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      textTheme: Typography.blackMountainView,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // ✅ can't be const
        ),
        color: surface,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campaign Builder',
      theme: theme,
      routes: {
        '/': (ctx) => const AuthScreen(),
        '/create_campaign': (ctx) => const CreateCampaignScreen(),
        '/dashboard': (ctx) => const DashboardScreen(),
        '/phone_auth': (ctx) => PhoneAuthPage(),
        '/customer': (ctx) => CustomerPage(),
        '/colab_request': (ctx) => ColobRequestList(),
      },
      initialRoute: '/colab_request',
    );
  }
}
