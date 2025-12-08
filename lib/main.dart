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
//import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';
//import 'services/matchmaking_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/searching_for_opponent.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'quiz_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:formularacing/services/database_helper.dart';

// ← added SplashScreen import

class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return FadeTransition(opacity: animation, child: child);
  }
  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);
}

// ............. Chunk 1 MAIN FUNCTION .............
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;

  // ADD THESE LINES to initialize the provider and load data
  QuizDataProvider quizProvider = QuizDataProvider();
  await quizProvider.loadAllQuizData();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((value) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => quizProvider,
        child: const FormulaRaceApp(), // Your main app widget
      ),
    );
  });
}

// ............. Chunk 2 APP WIDGET .............
class FormulaRaceApp extends StatelessWidget {
  const FormulaRaceApp({super.key});

  @override
  Widget build(BuildContext context) {

    final ThemeData base = ThemeData.dark();

    return MaterialApp(
      title: 'Formula Race',
      theme: ThemeData(
       fontFamily: GoogleFonts.poppins().fontFamily,
        brightness: Brightness.dark, // Example: Set a dark theme globally
        scaffoldBackgroundColor: Colors.black,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadePageTransitionsBuilder(),
            TargetPlatform.iOS: FadePageTransitionsBuilder(),
          },
        ),// Example: Set default background color
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        //'/clear_mistakes': (context) => const SoloScreen(selectedChapter: 'mistake',userId:userId),
      },
    );
  }
}
