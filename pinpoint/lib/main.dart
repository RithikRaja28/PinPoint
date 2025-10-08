import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pinpoint/root_screen.dart';
import 'package:pinpoint/screens/collab_request_store.dart';
import 'package:pinpoint/screens/collab_request_list.dart';
import 'package:pinpoint/screens/create_campaign_screen.dart';
import 'package:pinpoint/screens/customer_screen.dart';
import 'package:pinpoint/screens/dashboard_screen.dart';
import 'package:flutter/services.dart';
import 'package:pinpoint/screens/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pinpoint/screens/splash_screen.dart';
import 'package:pinpoint/services/phone_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pinpoint/screens/shops_list_screen.dart';
import 'package:pinpoint/screens/shop_detail_screen.dart';

import 'dart:async';
import 'dart:ui';

// Existing screens

// Newly added community screens
import 'package:pinpoint/screens/community_feed_screen.dart';
import 'package:pinpoint/screens/create_post_screen.dart';

Future<void> main() async {
  // Load environment variables from .env file
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("⚠️ .env file not found! Defaulting to empty values.");
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Handle framework-level errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('🔥 Flutter framework error: ${details.exception}');
    print(details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    print('🚨 Async error: $error');
    print(stack);
    return true;
  };

  debugDefaultTargetPlatformOverride = TargetPlatform.android;

  runApp(const CampaignApp());
}

class CampaignApp extends StatelessWidget {
  const CampaignApp({super.key});

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        // '/': (ctx) => const RootScreen(),
        '/': (ctx) => const SplashScreen(),
        '/root': (ctx) => const RootScreen(),
        '/create_campaign': (ctx) => const CreateCampaignScreen(),
        '/dashboard': (ctx) => const DashboardScreen(),
        '/community': (ctx) => const CommunityFeedScreen(),
        '/create_post': (ctx) => const CreatePostScreen(),
        '/phone_auth': (ctx) => PhoneAuthPage(),
        '/customer': (ctx) => CustomerPage(),
        '/colab_request': (ctx) => ColobRequestList(),
        '/shops': (ctx) => const ShopsListScreen(),
      },
      initialRoute: '/',
    );
  }
}
