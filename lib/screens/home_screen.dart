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






// ----------------------------------------------------
// HomeScreen Widget
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //String userId = '';

  @override
  void initState() {
    super.initState();
    //loadUserId();
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

              // . Chunk 3 MY MISTAKES BUTTON AT TOP .
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: screenWidth*0.04),
                  child: SizedBox(
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.15,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AITrackerScreen(userId: widget.userId)), // use real userId when ready
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                       // minimumSize: Size(screenWidth * 18, screenWidth * 1),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),side: BorderSide(color: Colors.red, width: 1.2),

                        ),
                        elevation: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'My Mistakes',
                              style: TextStyle(fontSize: screenWidth * 0.042, fontWeight:FontWeight.normal, color:Colors.redAccent)
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
                    

                  ],
                ),
              ),
              // ............. Chunk 5 BOTTOM TEXT (PHYSICS WITH RAKESH) .............
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  'Physics with Rakesh  |  IIT Madras',
                  style: TextStyle(
                    color: Color(0xFFC5C5C5),
                    fontSize: screenWidth * 0.045,

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

  const AnimatedButton({
    required this.screenWidth,
    required this.screenHeight,
    required this.onPressed,
    required this.child,
    required this.gradientColors,
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