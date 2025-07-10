// lib/screens/splash_screen.dart
// ----------------------------------------------------
// Splash Screen → clean layout:
// - Logo at exact center
// - Formula Race below logo
// - Physics with Rakesh → way below → grey
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ............. Chunk 1 DELAYED NAVIGATION .............
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // ............. Chunk 2 SCREEN SIZE VARIABLES .............
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0x000000), // dark background
      body: Center(
        child: Column(
          children: [
            const Spacer(),  // push logo to center

            // ............. Chunk 3 LOGO IMAGE .............
            Image.asset(
              'assets/logo.png',
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
            ),

            SizedBox(height: screenHeight * 0.02),

            // ............. Chunk 4 APP NAME TEXT .............
            const Text(
              'Formula Racing',
              style: TextStyle(
                fontSize: 32,
                color: Color(0xFF00FFFF),
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),  // push subtitle way down

            // ............. Chunk 5 SUBTITLE TEXT .............
            const Text(
              'Physics with Rakesh',
              style: TextStyle(
                fontSize: 23,
                color: Colors.grey,
              ),
            ),

            SizedBox(height: screenHeight * 0.035),  // small bottom spacing
          ],
        ),
      ),
    );
  }
}
