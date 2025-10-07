import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinpoint/screens/create_campaign_screen.dart';
import 'package:pinpoint/screens/dashboard_screen.dart';
import 'package:pinpoint/screens/auth_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pinpoint/screens/shops_list_screen.dart';
import 'package:pinpoint/screens/shop_detail_screen.dart';

import 'dart:async';
import 'dart:ui';

Future<void> main() async {
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("⚠️ .env file not found! Defaulting to empty values.");
  }
  WidgetsFlutterBinding.ensureInitialized();

  // Framework-level errors (UI)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('🔥 Flutter framework error: ${details.exception}');
    print(details.stack);
  };

  // Async or isolate-level errors
  PlatformDispatcher.instance.onError = (error, stack) {
    print('🚨 Async error: $error');
    print(stack);
    return true;
  };
  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  runApp(CampaignApp());
}

class CampaignApp extends StatelessWidget {
  const CampaignApp({super.key});

  // Pastel / light palette + accent gradient
  static const Color primary = Color(0xFF6A00F8); // deep accent
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
        '/shops': (ctx) => const ShopsListScreen(),
      },
      initialRoute: '/',
    );
  }
}
