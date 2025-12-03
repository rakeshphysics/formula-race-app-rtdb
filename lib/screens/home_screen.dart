// ----------------------------------------------------
// HomeScreen.dart — Corrected version based on your original
// - Solo Play button → unchanged
// - Online Play button → unchanged
// - AI Tracker button → now active (Chunk 3 updated)
// - Bottom text → unchanged
// ----------------------------------------------------

import 'package:flutter/material.dart';
//import 'solo_screen.dart';
//import 'online_play_screen.dart';
import 'solo_mode_selection_screen.dart';
import 'ai_tracker_screen.dart'; // Add this import
//import 'package:shared_preferences/shared_preferences.dart';
//import 'searching_for_opponent.dart';
//import 'dart:io';
//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:formularacing/services/matchmaking_service.dart'; // For MatchmakingService
//import 'package:formularacing/screens/qr_host_screen.dart';
import 'multiplayer_selection_screen.dart';
import 'package:flutter/services.dart';
//import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';








// ----------------------------------------------------
// HomeScreen Widget
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin { // Add mixin
  Timer? _timer;
  int _charIndex = 0;
  final String _fullAiMessage = "Good morning! Let's solve some questions.";
  String _displayedAiMessage = "";
  late AnimationController _breathingController; // <-- ADD THIS
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
    _breathingController = AnimationController( // <-- ADD THIS BLOCK
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _breathingAnimation = Tween<double>(begin: 0.18, end: 0.22).animate( // <-- ADD THIS BLOCK
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _breathingController.forward();
      }
    });

    _breathingController.forward();
  }

  void _startTypingAnimation() {
    const typingSpeed = Duration(milliseconds: 70);
    _timer = Timer.periodic(typingSpeed, (timer) {
      if (_charIndex < _fullAiMessage.length) {
        setState(() {
          _charIndex++;
          _displayedAiMessage = _fullAiMessage.substring(0, _charIndex);
        });
      } else {
        _timer?.cancel();
        _breathingController.stop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose(); // Important: cancel the timer to avoid memory leaks
    super.dispose();
  }

  //Future<void> loadUserId() async {
   // final prefs = await SharedPreferences.getInstance();
   // final storedId = prefs.getString('user_id');
   // if (storedId != null) {
     // setState(() {
      //  userId = storedId;
    //  });
   // } else {
     // print("No user ID found");
   // }
 // }

  Widget build(BuildContext context) {

    // --------- SCREEN DIMENSIONS ----------
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;


    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.cyan, width: 1.2),
              ),
              backgroundColor: Color(0xFF000000),
              title: Text(
                'Exit App ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: screenWidth*0.042),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.cyan, width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child:  Text(
                    'No',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth*0.04,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth*0.03),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.cyan, width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child:  Text(
                    'Yes',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth*0.04, fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            );
          },
        );

        if (shouldPop == true) {

          SystemNavigator.pop();

          return true; // Indicate that the pop action is handled (though SystemNavigator.pop takes over)
        }
        return shouldPop ?? false;
      },
    child: Scaffold(

      // ............. Chunk 1 BACKGROUND SOLID BLACK.............
      body: Container(
        color: Colors.black,
        child: SafeArea(
        // ............. Chunk 2 SAFE AREA CONTENT .............

          child: Column(
            children: [
              // =========== TOP HALF: AI CHAT AREA ===========
              Expanded(
                flex: 1, // This makes it take up half the space
                child: Container( // Placeholder for your AI chat UI
                  width: double.infinity,
                  child: Column(
                    children: [
                      // You can re-add your title here
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        child: Text(
                          'Formula Racing',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFA8A8A8),
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      // This is where your AI chat UI will go
                      // =========== AI AVATAR AND CHAT BUBBLE ===========
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // --- AVATAR ---
                            // Placeholder for your animated blob
                            // --- AVATAR ---
                            AnimatedBuilder(
                              animation: _breathingAnimation,
                              builder: (context, child) {
                                return Icon(
                                  Icons.bubble_chart,
                                  color: Colors.cyan,
                                  // The size is now driven by the animation!
                                  size: screenWidth * _breathingAnimation.value,
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // --- CHAT BUBBLE ---
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E), // Dark grey bubble
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _displayedAiMessage, // Use the state variable here
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Divider(
                  color: Colors.grey.withOpacity(0.5),
                  thickness: 1,
                ),
              ),


              // ............. Chunk 4 SOLO / ONLINE CENTERED .............
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // Solo Play button → your original style




                    // Online Play button → your original style
                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,

                      onPressed: () {
                        //print('✅Navigating to MultiplayerSelectionScreen with userId: ${widget.userId}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiplayerSelectionScreen(userId: widget.userId),
                            // Navigate to the new page
                          ),
                        );
                      },
                      gradientColors: const [Color(0xFFFFA500), Color(
                          0xFF874A01)],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children:  [
                          Text(
                            'Play Friend',
                            style: TextStyle(fontSize: screenWidth * 0.057, color: Colors.white,fontWeight: FontWeight.normal),
                          ),

                        ],
                      ),
                    ),

                    SizedBox(height: screenWidth*0.055),
                    //SizedBox(height: screenWidth*0.055),

                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,


                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SoloModeSelectionScreen(userId: widget.userId)),
                        );
                      },
                      gradientColors: const [Color(0xFF00FFFF), Color(0xFF006C6C)],
                      child:  Text(
                        'Play Solo',
                        style: TextStyle(fontSize: screenWidth * 0.057, color: Colors.white,fontWeight: FontWeight.normal),
                      ),
                    ),

                    SizedBox(height: screenWidth*0.055),

                    AnimatedButton(
                      screenWidth: screenWidth,
                      screenHeight: screenWidth,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AITrackerScreen(userId: widget.userId)),
                        );
                      },
                      gradientColors: const [Colors.red, Color(0xFF8B0000)], // Red gradient
                      color: const Color(0xFF000000), // Black background
                      child: Text(
                        'My Mistakes',
                        style: TextStyle(fontSize: screenWidth * 0.057, color: Colors.redAccent, fontWeight: FontWeight.normal),
                      ),
                    ),

                  ],
                ),
              ),
              // ............. Chunk 5 BOTTOM TEXT (PHYSICS WITH RAKESH) .............
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'Physics with Rakesh  |  IIT Madras',
                  style: TextStyle(
                    color: Color(0xFFA8A8A8),
                    fontSize: screenWidth * 0.05,

                  ),
                ),
              ),

            ],
          ),
        ),
    )
    ),
    );
  }//
}

//...............................CHUNK 6............. ANIMATED BUTTON..................................
class AnimatedButton extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final VoidCallback onPressed;
  final Widget child;
  final List<Color> gradientColors;
  final Color color;


  const AnimatedButton({
    required this.screenWidth,
    required this.screenHeight,
    required this.onPressed,
    required this.child,
    required this.gradientColors,
    this.color = Colors.black,

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
          painter: GradientBorderPainter(gradientColors: widget.gradientColors),
          child: Container(
            width: widget.screenWidth * 0.8,
            height: widget.screenHeight * 0.19,
            decoration: BoxDecoration(
              color: widget.color,
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
  final List<Color> gradientColors; // ADD THIS LINE

  GradientBorderPainter({required this.gradientColors});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(4));
    final gradient = LinearGradient(
      colors: gradientColors,
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