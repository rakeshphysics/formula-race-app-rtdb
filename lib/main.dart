// lib/main.dart
// ----------------------------------------------------
// Main entry point of Formula Race App:
// - Firebase initialized
// - SplashScreen shown first
// - Then navigate to HomeScreen
// - CHUNK FORMAT
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'screens/solo_screen.dart';
import 'screens/online_play_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/matchmaking_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';  // ← added SplashScreen import

// ............. Chunk 1 MAIN FUNCTION .............
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FormulaRaceApp());
}

// ............. Chunk 2 APP WIDGET .............
class FormulaRaceApp extends StatelessWidget {
  const FormulaRaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formula Race',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/clear_mistakes': (context) => const SoloScreen(selectedChapter: 'mistake'), // ✅ Add this route
      },
    );
  }
}
