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
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/matchmaking_service.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/searching_for_opponent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ← added SplashScreen import

// ............. Chunk 1 MAIN FUNCTION .............
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- START: Firebase Anonymous Authentication ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = _auth.currentUser;

  // If no user is signed in (including anonymous)
  if (user == null) {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      user = userCredential.user;
      print("Signed in anonymously with UID: ${user?.uid}");
    } catch (e) {
      print("Error signing in anonymously: $e");
      // Handle error, e.g., show an error screen and prevent app from running
      // For now, re-throw to stop app if anonymous sign-in fails
      rethrow;
    }
  }

  // At this point, user should have an authenticated Firebase UID
  // You can now rely on user?.uid for all Realtime Database operations
  // If you still need a local 'user_id' in SharedPreferences for other purposes,
  // it's best to use the Firebase Auth UID as that local ID.
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('user_id')) {
    // Use the Firebase Auth UID as your local user_id
    final generatedId = user!.uid; // user should not be null here
    await prefs.setString('user_id', generatedId);
    print('Generated userId from Firebase Auth: $generatedId');
  } else {
    // Optional: If you had an old local_app_id, you might want to log it
    // or migrate data if necessary. For now, we assume the Firebase Auth UID
    // will be the primary identifier for database operations.
    print('Existing SharedPreferences user_id: ${prefs.getString('user_id')}');
  }

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
