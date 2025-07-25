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
      print("✅ Firebase initialized in SplashScreen.");

      // 2. Perform Anonymous Authentication
      final FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;

      if (user == null) {
        UserCredential userCredential = await _auth.signInAnonymously();
        user = userCredential.user;
        print("✅ Signed in anonymously with UID: ${user?.uid}");
      } else {
        print("ℹ️ Already signed in anonymously with UID: ${user.uid}");
      }

      // 3. Ensure local user_id in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String userIdFromSplash = user!.uid; // Get the userId after auth
      if (!prefs.containsKey('user_id')) {
        await prefs.setString('user_id', userIdFromSplash);
        print('✅ Generated userId from Firebase Auth: $userIdFromSplash and saved to SharedPreferences.');
      } else {
        print('ℹ️ Existing SharedPreferences user_id: ${prefs.getString('user_id')}');
      }

      // --- CONSOLIDATED NAVIGATION LOGIC ---
      // Calculate time elapsed and wait for minimum display time if necessary
      final endTime = DateTime.now();
      final Duration timeElapsed = endTime.difference(startTime);

      if (timeElapsed < minDisplayTime) {
        await Future.delayed(minDisplayTime - timeElapsed);
        print("⏳ Splash screen extended for visibility.");
      }

      print("🔍 DEBUG NAV: Checking mounted status before scheduling post-frame callback. Mounted: $mounted");
      // FINAL NAVIGATION: Ensure it happens after delay AND after a frame is drawn, with mounted check
      Future.microtask(() {
        if (mounted) { // Crucial: Check mounted status before navigating
          print("🚀 Navigating to Home Screen now (via microtask)."); // Debug print
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(userId: userIdFromSplash)),
          );
        } else {
          print("🚫 Widget unmounted before microtask navigation. Cannot navigate."); // Debug print
        }
      });
      // --- END CONSOLIDATED NAVIGATION LOGIC ---

    } catch (e) {
      print("❌ Error during SplashScreen initialization: $e");
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
      body: Center( // This centers the content horizontally
        child: SizedBox( // Constraint the Column to full screen height
          height: screenHeight, // Make SizedBox take full screen height
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers the content (logo + text block) vertically within the SizedBox
            mainAxisSize: MainAxisSize.max, // Ensure Column tries to take max space provided by SizedBox

            children: [
              const Spacer(), // Pushes the logo-text block down from the top

              // ............. Chunk 3 LOGO IMAGE .............
              Image.asset(
                'assets/logo.png', // Ensure this path is correct
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
              ),

              SizedBox(height: screenHeight * 0.04), // Space between logo and text

              // ............. Chunk 4 APP NAME TEXT .............
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Physics Revision', // Line 1: The subject and exam context
                    style: GoogleFonts.poppins(
                      fontSize: 20, // Slightly larger to be the main subject line
                      color: const Color(0xFFD3D3D3), // Lighter grey
                      fontWeight: FontWeight.normal, // Make it bold for more emphasis
                    ),
                  ),
                  const SizedBox(height: 9), // Increased space for clear separation between context and punchline
                  Text(
                    ' GAMIFIED !', // Line 2: The punchline, largest and white
                    style: GoogleFonts.poppins(
                      fontSize: 28, // Largest font size for maximum impact
                      color: Colors.white, // White for maximum contrast
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),

              const Spacer(), // Pushes the logo-text block up from the bottom
              Text(
                'For JEE Mains/Adv', // Line 1: The subject and exam context
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFFA3A3A3), // Lighter grey
                  fontWeight: FontWeight.normal, // Make it bold for more emphasis
                ),
              ),
              // Your commented out "Formula Racing" text or other bottom content would go here
            ],
          ),
        ),
      ),
    );
  }
}
