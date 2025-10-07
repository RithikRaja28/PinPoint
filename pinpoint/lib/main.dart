// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold();
//   }
// }
import 'package:flutter/material.dart';
import 'package:pinpoint/screens/create_campaign_screen.dart';
import 'package:pinpoint/screens/dashboard_screen.dart';
import 'package:pinpoint/screens/auth_screen.dart';
import 'server_page.dart';
import 'client_page.dart';

void main() {
  runApp(const CampaignApp());
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
    return MaterialApp(
      title: 'Socket Hello Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const RoleSelectionPage(),
    );
  }
}

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud),
              label: const Text('Run as Server'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServerPage()),
                );
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone_android),
              label: const Text('Run as Client'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientPage()),
                );
              },
            ),
          ],
        ),
      ),
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
      cardTheme: CardThemeData( elevation: 8, shape: RoundedRectangleBorder( 
        borderRadius: BorderRadius.circular(16), // ✅ can't be const 
        ), 
        color: surface, shadowColor: Colors.black12, 
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
      },
      initialRoute: '/',
    );
  }
}
