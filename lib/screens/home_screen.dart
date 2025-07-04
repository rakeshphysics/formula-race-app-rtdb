// ----------------------------------------------------
// HomeScreen.dart — Corrected version based on your original
// - Solo Play button → unchanged
// - Online Play button → unchanged
// - AI Tracker button → now active (Chunk 3 updated)
// - Bottom text → unchanged
// ----------------------------------------------------

import 'package:flutter/material.dart';
import 'solo_screen.dart';
//import 'online_play_screen.dart';
import 'solo_mode_selection_screen.dart';
import 'ai_tracker_screen.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';
import 'searching_for_opponent.dart';
import 'dart:io';





// ----------------------------------------------------
// HomeScreen Widget
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userId = '';

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('user_id');
    if (storedId != null) {
      setState(() {
        userId = storedId;
      });
    } else {
      print("No user ID found");
    }
  }

  Widget build(BuildContext context) {

    // --------- SCREEN DIMENSIONS ----------
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(

      // ............. Chunk 1 BACKGROUND SOLID BLACK.............
      body: Container(
        color: Colors.black,
        child: SafeArea(
        // ............. Chunk 2 SAFE AREA CONTENT .............

          child: Column(
            children: [

              // . Chunk 3 MY MISTAKES BUTTON AT TOP .
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: SizedBox(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AITrackerScreen(userId: 'test_user')), // use real userId when ready
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),side: BorderSide(color: Colors.red, width: 1.2),

                        ),
                        elevation: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'My Mistakes',
                              style: TextStyle(fontSize: 17, fontWeight:FontWeight.normal, color:Colors.redAccent)
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ............. Chunk 4 SOLO / ONLINE CENTERED .............
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // Solo Play button → your original style
                    AnimatedButton(
                      screenWidth: screenWidth*1.2,
                      screenHeight: screenHeight*1.3,

                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SoloModeSelectionScreen()),
                        );
                      },
                      child: const Text(
                        'Solo Play',
                        style: TextStyle(fontSize: 26, color: Colors.white,fontWeight: FontWeight.normal),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Online Play button → your original style
                    AnimatedButton(
                      screenWidth: screenWidth*1.2,
                      screenHeight: screenHeight*1.3,
                        onPressed: () {
                          if (userId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchingForOpponent(userId: userId),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User ID not ready yet')),
                            );
                          }
                        },

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Play with Friend',
                            style: TextStyle(fontSize: 26, color: Colors.white,fontWeight: FontWeight.normal),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '(11th + 12th)',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),

              // ............. Chunk 5 BOTTOM TEXT (PHYSICS WITH RAKESH) .............
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'Physics with Rakesh',
                  style: TextStyle(
                    color: Color(0xCF00FFFF),
                    fontSize: 20,
                  ),
                ),
              ),

            ],
          ),
        ),
    )
    );
  }//
}
//...............................CHUNK 6............. ANIMATED BUTTON..................................
class AnimatedButton extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onPressed;
  final Widget child;

  const AnimatedButton({
    required this.screenWidth,
    required this.screenHeight,
    required this.onPressed,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: CustomPaint(
          painter: GradientBorderPainter(),
          child: Container(
            width: widget.screenWidth * 0.7,
            height: widget.screenHeight * 0.07,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                splashColor: Colors.grey.withOpacity(0.3),
                highlightColor: Colors.grey.withOpacity(0.1),
                splashFactory: InkRipple.splashFactory,
                borderRadius: BorderRadius.circular(4),
                onTap: widget.onPressed,
                child: Center(child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(4));
    final gradient = LinearGradient(
      colors: [Color(0xFF00FFFF), Color(0xFF006C6C)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}