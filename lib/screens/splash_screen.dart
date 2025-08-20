// lib/screens/splash_screen.dart
// ----------------------------------------------------
// Splash Screen → clean layout:
// - Logo at exact center
// - Formula Race below logo
// - Physics with Rakesh → way below → grey
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseAndNavigate();
  }



  // Inside _SplashScreenState class
  Future<void> _initializeFirebaseAndNavigate() async {
    try {
      const Duration minDisplayTime = Duration(seconds: 3); // Set your desired minimum duration
      final startTime = DateTime.now();

      // 1. Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      //print("✅ Firebase initialized in SplashScreen.");

      // 2. Perform Anonymous Authentication
      final FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;

      if (user == null) {
        UserCredential userCredential = await _auth.signInAnonymously();
        user = userCredential.user;
        //print("✅ Signed in anonymously with UID: ${user?.uid}");
      } else {
        //print("ℹ️ Already signed in anonymously with UID: ${user.uid}");
      }

      // 3. Ensure local user_id in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String userIdFromSplash = user!.uid; // Get the userId after auth
      if (!prefs.containsKey('user_id')) {
        await prefs.setString('user_id', userIdFromSplash);
        //print('✅ Generated userId from Firebase Auth: $userIdFromSplash and saved to SharedPreferences.');
      } else {
       // print('ℹ️ Existing SharedPreferences user_id: ${prefs.getString('user_id')}');
      }

      // --- CONSOLIDATED NAVIGATION LOGIC ---
      // Calculate time elapsed and wait for minimum display time if necessary
      final endTime = DateTime.now();
      final Duration timeElapsed = endTime.difference(startTime);

      if (timeElapsed < minDisplayTime) {
        await Future.delayed(minDisplayTime - timeElapsed);
        //print("⏳ Splash screen extended for visibility.");
      }

     // print("🔍 DEBUG NAV: Checking mounted status before scheduling post-frame callback. Mounted: $mounted");
      // FINAL NAVIGATION: Ensure it happens after delay AND after a frame is drawn, with mounted check
      Future.microtask(() {
        if (mounted) { // Crucial: Check mounted status before navigating
          //print("🚀 Navigating to Home Screen now (via microtask)."); // Debug print
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userId: userIdFromSplash)),
          );
        } else {
          //print("🚫 Widget unmounted before microtask navigation. Cannot navigate."); // Debug print
        }
      });
      // --- END CONSOLIDATED NAVIGATION LOGIC ---

    } catch (e) {
      //print("❌ Error during SplashScreen initialization: $e");
      // Handle initialization errors (e.g., show an error message to the user, retry option)
    }
  }




  @override
  Widget build(BuildContext context) {
    // ............. Chunk 2 SCREEN SIZE VARIABLES .............
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black, // Assuming this is Color(0x000000) from your previous code
      body: Stack(
        children: [
          // The main centered content (logo and text block)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                ),
                SizedBox(height: screenHeight * 0.04),
                Text(
                  'Physics Formulas',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.045,
                    color: const Color(0xFFD3D3D3),
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'GAMIFIED !',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    color: const Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // The text fixed to the bottom of the screen
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              child: Text(
                'For JEE Mains/Adv',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFFD3D3D3),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
